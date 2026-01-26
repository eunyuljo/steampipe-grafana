#!/bin/bash

# =============================================================================
# Steampipe + Grafana 자동 설치 스크립트 (로컬 설치)
# 지원 OS: Amazon Linux 2023, Ubuntu 20.04+, CentOS/RHEL 8+
# 요구사항: Python 3.10+ (pyenv 권장)
# =============================================================================

set -e  # 오류 발생 시 스크립트 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# OS 감지 함수
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        log_error "운영체제를 감지할 수 없습니다."
        exit 1
    fi

    log_info "감지된 OS: $OS $VERSION"
}

# Python 환경 체크 함수
check_python_environment() {
    log_info "Python 환경 확인 중..."

    # Python 3 설치 확인
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3가 설치되지 않았습니다."
        log_info "Python 3.10+ 설치 가이드:"
        echo "  Amazon Linux: sudo dnf install python3 python3-pip"
        echo "  Ubuntu: sudo apt install python3 python3-pip"
        echo "  또는 pyenv 사용: pyenv install 3.10.13 && pyenv global 3.10.13"
        exit 1
    fi

    # Python 버전 확인
    local python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    local required_version="3.10"

    if [[ $(echo "$python_version >= $required_version" | bc -l 2>/dev/null || echo "0") -eq 1 ]] ||
       [[ "$python_version" == "3.10" ]] || [[ "$python_version" > "3.10" ]]; then
        log_success "Python $python_version 환경 확인됨"

        # pyenv 사용 여부 확인
        if command -v pyenv &> /dev/null && [[ "$PYENV_VERSION" != "" ]] || [[ -f ~/.pyenv/version ]]; then
            local pyenv_version=$(pyenv version 2>/dev/null | cut -d' ' -f1)
            log_success "pyenv 환경 사용 중: $pyenv_version"
        fi
    else
        log_error "Python 버전이 요구사항에 맞지 않습니다. (현재: $python_version, 필요: $required_version+)"
        log_info "Python 3.10+ 설치 후 다시 시도하세요."
        exit 1
    fi

    # pip 확인
    if ! command -v pip3 &> /dev/null; then
        log_warning "pip3가 설치되지 않았습니다. 선택적 Python 스크립트 실행에 제한이 있을 수 있습니다."
    fi
}

# 필수 도구 설치 함수
install_prerequisites() {
    log_info "필수 도구 설치 중..."

    case $OS in
        "amzn")
            # curl 충돌 해결을 위해 --allowerasing 사용
            sudo dnf update -y
            sudo dnf install -y --allowerasing curl wget unzip || {
                log_warning "curl 설치 중 충돌 발생, 기존 curl 사용"
                sudo dnf install -y wget unzip
            }
            ;;
        "ubuntu")
            sudo apt update
            sudo apt install -y curl wget unzip
            ;;
        "centos"|"rhel")
            sudo dnf update -y
            sudo dnf install -y curl wget unzip
            ;;
        *)
            log_error "지원하지 않는 운영체제입니다: $OS"
            exit 1
            ;;
    esac

    log_success "필수 도구 설치 완료"
}

# Steampipe 설치 함수
install_steampipe() {
    log_info "Steampipe 설치 중..."

    # Steampipe 바이너리 다운로드 및 설치 (개발 브랜치 스크립트 사용 - 인증 문제 해결됨)
    if ! sudo /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/turbot/steampipe/refs/heads/develop/scripts/install.sh)" 2>/dev/null; then
        log_warning "공식 설치 스크립트 실패, 수동 설치 시도 중..."

        # 수동 설치 방법
        local STEAMPIPE_VERSION="v2.3.2"
        local INSTALL_DIR="/usr/local/bin"
        local ARCH="linux_amd64"

        # 특정 버전 다운로드 (안정적인 버전 사용)
        wget -q "https://github.com/turbot/steampipe/releases/download/v2.3.2/steampipe_${ARCH}.tar.gz" -O /tmp/steampipe.tar.gz

        if [[ ! -f /tmp/steampipe.tar.gz ]]; then
            log_error "Steampipe 다운로드에 실패했습니다."
            exit 1
        fi

        # 압축 해제 및 설치
        tar -xzf /tmp/steampipe.tar.gz -C /tmp/
        sudo mv /tmp/steampipe "$INSTALL_DIR/"
        sudo chmod +x "$INSTALL_DIR/steampipe"

        # 임시 파일 정리
        rm -f /tmp/steampipe.tar.gz /tmp/steampipe
    fi

    # 설치 확인
    if ! command -v steampipe &> /dev/null; then
        log_error "Steampipe 설치에 실패했습니다."
        exit 1
    fi

    log_success "Steampipe 설치 완료: $(steampipe --version)"
}

# AWS 플러그인 설치 및 설정 함수
setup_steampipe_aws() {
    log_info "Steampipe AWS 플러그인 설치 중..."

    # AWS 플러그인 설치
    steampipe plugin install aws

    # Steampipe 서비스 시작
    log_info "Steampipe 서비스 시작 중..."
    steampipe service start

    # 잠시 대기 (서비스 시작 시간)
    sleep 5

    # AWS 연결 테스트
    log_info "AWS 연결 테스트 중..."
    if steampipe query "SELECT count(*) FROM aws_ec2_instance" &>/dev/null; then
        log_success "AWS 연결 테스트 성공"
    else
        log_warning "AWS 연결 테스트 실패 - AWS 자격 증명을 확인하세요"
        log_info "AWS 자격 증명 설정 방법:"
        echo "  1. AWS CLI 설정: aws configure"
        echo "  2. IAM 역할 사용 (EC2의 경우)"
        echo "  3. 환경 변수: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
    fi

    log_success "Steampipe AWS 플러그인 설정 완료"
}

# Grafana 설치 함수
install_grafana() {
    log_info "Grafana 설치 중..."

    case $OS in
        "amzn"|"centos"|"rhel")
            # RPM 기반 시스템 - Grafana 저장소 추가 필요
            log_info "Grafana 저장소 추가 중..."
            sudo tee /etc/yum.repos.d/grafana.repo > /dev/null << 'EOF'
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
            log_success "Grafana 저장소 추가 완료"
            sudo dnf install -y grafana
            ;;
        "ubuntu")
            # DEB 기반 시스템
            sudo apt-get install -y software-properties-common
            sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
            wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
            sudo apt-get update
            sudo apt-get install -y grafana
            ;;
        *)
            log_error "지원하지 않는 운영체제입니다: $OS"
            exit 1
            ;;
    esac

    log_success "Grafana 설치 완료"
}

# Grafana 서비스 설정 함수
setup_grafana_service() {
    log_info "Grafana 서비스 설정 중..."

    # systemd 서비스 설정
    sudo systemctl daemon-reload
    sudo systemctl enable grafana-server.service
    sudo systemctl start grafana-server.service

    # 서비스 상태 확인
    sleep 3
    if sudo systemctl is-active --quiet grafana-server; then
        log_success "Grafana 서비스 시작 완료"
    else
        log_error "Grafana 서비스 시작에 실패했습니다."
        sudo systemctl status grafana-server
        exit 1
    fi
}

# Grafana 데이터소스 자동 설정 함수
setup_grafana_datasource() {
    log_info "Grafana 데이터소스 자동 설정 중..."

    # Grafana가 완전히 시작될 때까지 대기
    local max_attempts=30
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if curl -s -f http://localhost:3000/api/health &>/dev/null; then
            log_success "Grafana 웹 서비스 준비 완료"
            break
        fi

        if [[ $attempt -eq $max_attempts ]]; then
            log_error "Grafana 웹 서비스 시작 대기 시간 초과"
            return 1
        fi

        log_info "Grafana 시작 대기 중... ($attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done

    # Steampipe 비밀번호 가져오기
    local steampipe_password
    steampipe_password=$(steampipe service status --show-password 2>/dev/null | grep "Password:" | awk '{print $2}' || echo "")

    if [[ -z "$steampipe_password" ]]; then
        log_error "Steampipe 비밀번호를 가져올 수 없습니다."
        return 1
    fi

    # 데이터소스 JSON 생성
    local datasource_json=$(cat <<EOF
{
  "name": "Steampipe",
  "type": "postgres",
  "access": "proxy",
  "url": "localhost:9193",
  "database": "steampipe",
  "user": "steampipe",
  "password": "$steampipe_password",
  "isDefault": true,
  "jsonData": {
    "sslmode": "disable",
    "postgresVersion": 1300,
    "timescaledb": false
  }
}
EOF
)

    # Grafana API를 통해 데이터소스 생성
    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u admin:admin \
        -d "$datasource_json" \
        http://localhost:3000/api/datasources 2>/dev/null)

    if echo "$response" | grep -q '"message":"Datasource added"' || echo "$response" | grep -q '"name":"Steampipe"'; then
        log_success "Steampipe 데이터소스 자동 생성 완료"

        # 연결 테스트
        log_info "데이터소스 연결 테스트 중..."
        local test_response
        test_response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -u admin:admin \
            http://localhost:3000/api/datasources/name/Steampipe/test 2>/dev/null)

        if echo "$test_response" | grep -q '"status":"success"'; then
            log_success "데이터소스 연결 테스트 성공"
        else
            log_warning "데이터소스 연결 테스트 실패 - 수동으로 확인해주세요"
        fi
    else
        log_warning "데이터소스 자동 생성 실패 - 수동으로 설정해주세요"
        log_info "수동 설정 정보:"
        echo "  URL: http://localhost:3000"
        echo "  Type: PostgreSQL"
        echo "  Host: localhost:9193"
        echo "  Database: steampipe"
        echo "  User: steampipe"
        echo "  Password: $steampipe_password"
    fi
}

# 대시보드 및 설정 파일 생성 함수
create_dashboard_files() {
    log_info "대시보드 설정 파일 생성 중..."

    # Grafana 데이터소스 설정 파일 생성 (백업용)
    cat > grafana-datasource.yaml << 'EOF'
apiVersion: 1

datasources:
  - name: Steampipe
    type: postgres
    access: proxy
    url: localhost:9193
    database: steampipe
    user: steampipe
    password: ${STEAMPIPE_PASSWORD}
    sslmode: disable
    isDefault: true
EOF

    # 환경 설정 파일 생성
    cat > .env.example << 'EOF'
# Steampipe 데이터베이스 연결 정보
STEAMPIPE_HOST=localhost
STEAMPIPE_PORT=9193
STEAMPIPE_DATABASE=steampipe
STEAMPIPE_USER=steampipe
STEAMPIPE_PASSWORD=

# Grafana 설정
GRAFANA_URL=http://localhost:3000
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin

# AWS 설정 (선택사항)
AWS_REGION=ap-northeast-2
AWS_PROFILE=default
EOF

    log_success "설정 파일 생성 완료"
}

# Grafana 대시보드 자동 임포트 함수
import_grafana_dashboard() {
    log_info "Grafana 대시보드 자동 임포트 중..."

    # 대시보드 JSON 파일이 존재하는지 확인
    if [[ ! -f "grafana-dashboard-ec2.json" ]]; then
        log_warning "대시보드 JSON 파일이 없습니다 - 수동으로 임포트해주세요"
        return
    fi

    # Grafana 서비스가 준비될 때까지 대기
    local max_attempts=30
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if curl -s -f http://localhost:3000/api/health &>/dev/null; then
            break
        fi
        log_info "Grafana 서비스 준비 대기 중... ($attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done

    if [[ $attempt -gt $max_attempts ]]; then
        log_error "Grafana 서비스 준비 시간 초과"
        return
    fi

    # 데이터소스 UID 가져오기
    local datasource_uid
    datasource_uid=$(curl -s -u admin:admin http://localhost:3000/api/datasources/name/Steampipe 2>/dev/null | grep -o '"uid":"[^"]*"' | cut -d'"' -f4)

    if [[ -z "$datasource_uid" ]]; then
        log_warning "데이터소스 UID를 가져올 수 없습니다 - 수동으로 대시보드를 임포트해주세요"
        return
    fi

    # 대시보드 JSON에서 datasource UID 치환
    local dashboard_json
    dashboard_json=$(sed "s/\${DS_STEAMPIPE}/$datasource_uid/g" grafana-dashboard-ec2.json)

    # 대시보드 임포트
    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u admin:admin \
        -d "$dashboard_json" \
        http://localhost:3000/api/dashboards/db 2>/dev/null)

    if echo "$response" | grep -q '"status":"success"' || echo "$response" | grep -q '"url":'; then
        log_success "AWS EC2 모니터링 대시보드 자동 임포트 완료"
        local dashboard_url
        dashboard_url=$(echo "$response" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$dashboard_url" ]]; then
            log_info "대시보드 URL: http://localhost:3000$dashboard_url"
        fi
    else
        log_warning "대시보드 자동 임포트 실패 - 수동으로 임포트해주세요"
        log_info "수동 임포트 방법:"
        echo "  1. http://localhost:3000 접속"
        echo "  2. + (Create) → Import 클릭"
        echo "  3. grafana-dashboard-ec2.json 파일 업로드"
        echo "  4. 데이터소스를 'Steampipe'로 선택"
    fi
}

# 연결 정보 출력 함수
display_connection_info() {
    log_info "연결 정보 수집 중..."

    # Steampipe 연결 정보 가져오기
    STEAMPIPE_INFO=$(steampipe service status --show-password 2>/dev/null || echo "서비스가 실행되지 않음")

    echo ""
    echo "============================================================================="
    echo "                        🎉 설치 완료! 🎉                                   "
    echo "============================================================================="
    echo ""
    echo "📊 Grafana 웹 인터페이스:"
    echo "   URL: http://localhost:3000"
    echo "   기본 로그인: admin / admin"
    echo ""
    echo "🗄️  Steampipe 데이터베이스:"
    echo "$STEAMPIPE_INFO"
    echo ""
    echo "📁 설정 파일 위치:"
    echo "   대시보드: grafana-dashboard-ec2.json"
    echo "   환경설정: .env.example"
    echo ""
    echo "🚀 다음 단계:"
    echo "   1. 브라우저에서 http://localhost:3000 접속"
    echo "   2. admin/admin으로 로그인"
    echo "   3. Steampipe 데이터소스가 자동으로 설정됨 ✅"
    echo "   4. 대시보드 JSON 파일 임포트 (grafana-dashboard-ec2.json)"
    echo ""
    echo "============================================================================="
}

# 메인 설치 함수
main() {
    echo "============================================================================="
    echo "                   Steampipe + Grafana 로컬 자동 설치                      "
    echo "============================================================================="
    echo ""

    # 루트 권한 확인
    if [[ $EUID -eq 0 ]]; then
        log_error "이 스크립트는 루트 사용자로 실행하지 마세요."
        exit 1
    fi

    # sudo 권한 확인
    if ! sudo -n true 2>/dev/null; then
        log_error "이 스크립트는 sudo 권한이 필요합니다."
        exit 1
    fi

    detect_os
    check_python_environment
    install_prerequisites
    install_steampipe
    setup_steampipe_aws
    install_grafana
    setup_grafana_service
    setup_grafana_datasource
    create_dashboard_files
    import_grafana_dashboard
    display_connection_info

    log_success "모든 설치가 완료되었습니다!"
}

# 스크립트 실행
main "$@"