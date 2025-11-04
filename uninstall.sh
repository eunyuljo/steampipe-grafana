#!/bin/bash

# =============================================================================
# Steampipe + Grafana 제거 스크립트
# 설치된 컴포넌트만 제거하고 스크립트는 보존합니다
# =============================================================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
}

# 확인 요청 함수
confirm_uninstall() {
    echo "============================================================================="
    echo "                        ⚠️  경고: 컴포넌트 제거 ⚠️                         "
    echo "============================================================================="
    echo ""
    echo "다음 항목들이 제거됩니다:"
    echo ""
    echo "🗄️  Steampipe:"
    echo "   • Steampipe 바이너리 및 설정"
    echo "   • 설치된 모든 플러그인"
    echo "   • 데이터베이스 및 캐시"
    echo ""
    echo "📊 Grafana:"
    echo "   • Grafana 서버 및 설정"
    echo "   • 모든 대시보드 및 데이터소스"
    echo "   • 사용자 데이터 및 플러그인"
    echo ""
    echo "📁 생성된 설정 파일들:"
    echo "   • .env 파일"
    echo "   • 로그 파일들"
    echo ""
    echo "✅ 보존되는 파일들:"
    echo "   • install-steampipe-grafana.sh"
    echo "   • verify-installation.sh"
    echo "   • uninstall.sh (이 스크립트)"
    echo "   • README.md"
    echo "   • grafana-dashboard-ec2.json"
    echo "   • grafana-datasource.yaml"
    echo "   • .env.example"
    echo ""
    echo "============================================================================="
    echo ""

    read -p "컴포넌트를 제거하시겠습니까? [y/N]: " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "제거가 취소되었습니다."
        exit 0
    fi
}

# Steampipe 서비스 중지 및 제거
remove_steampipe() {
    log_info "Steampipe 제거 중..."

    # 서비스 중지
    if command -v steampipe &> /dev/null; then
        steampipe service stop 2>/dev/null || true
        log_success "Steampipe 서비스 중지됨"
    fi

    # 바이너리 제거
    if [[ -f /usr/local/bin/steampipe ]]; then
        sudo rm -f /usr/local/bin/steampipe
        log_success "Steampipe 바이너리 제거됨"
    fi

    # 설정 디렉토리 제거
    if [[ -d ~/.steampipe ]]; then
        rm -rf ~/.steampipe
        log_success "Steampipe 설정 디렉토리 제거됨"
    fi

    # 캐시 디렉토리 제거
    if [[ -d ~/.cache/steampipe ]]; then
        rm -rf ~/.cache/steampipe
        log_success "Steampipe 캐시 디렉토리 제거됨"
    fi
}

# Grafana 서비스 중지 및 제거
remove_grafana() {
    log_info "Grafana 제거 중..."

    # 서비스 중지 및 비활성화
    if systemctl is-active --quiet grafana-server 2>/dev/null; then
        sudo systemctl stop grafana-server
        log_success "Grafana 서비스 중지됨"
    fi

    if systemctl is-enabled --quiet grafana-server 2>/dev/null; then
        sudo systemctl disable grafana-server
        log_success "Grafana 서비스 비활성화됨"
    fi

    # 패키지 제거
    case $OS in
        "amzn"|"centos"|"rhel")
            if rpm -qa | grep -q grafana; then
                sudo dnf remove -y grafana
                log_success "Grafana 패키지 제거됨"
            fi
            ;;
        "ubuntu")
            if dpkg -l | grep -q grafana; then
                sudo apt-get remove --purge -y grafana
                sudo apt-get autoremove -y
                log_success "Grafana 패키지 제거됨"
            fi
            ;;
    esac

    # 설정 및 데이터 디렉토리 제거
    local grafana_dirs=(
        "/etc/grafana"
        "/var/lib/grafana"
        "/var/log/grafana"
        "/usr/share/grafana"
    )

    for dir in "${grafana_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            sudo rm -rf "$dir"
            log_success "Grafana 디렉토리 제거됨: $dir"
        fi
    done
}

# 생성된 설정 파일만 제거 (스크립트는 보존)
remove_generated_files() {
    log_info "생성된 설정 파일 정리 중..."

    # 사용자가 생성한 파일들만 제거 (스크립트 파일은 보존)
    local files_to_remove=(
        ".env"                    # 사용자 환경 파일
        "queries.sql"            # 쿼리 파일
        "test.py"               # 테스트 스크립트
    )

    for file in "${files_to_remove[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_success "파일 제거됨: $file"
        fi
    done

    # 설치 시 생성되는 디렉토리 제거 (비어있는 경우만)
    if [[ -d ~/steampipe-grafana-setup ]] && [[ -z "$(ls -A ~/steampipe-grafana-setup 2>/dev/null)" ]]; then
        rmdir ~/steampipe-grafana-setup 2>/dev/null || true
        log_success "빈 설치 디렉토리 제거됨"
    fi

    log_success "생성된 파일 정리 완료 (스크립트 파일은 보존됨)"
}

# 포트 정리 확인
check_port_cleanup() {
    log_info "포트 사용 상태 확인 중..."

    # 포트 9193 (Steampipe) 확인
    if netstat -tuln 2>/dev/null | grep -q ":9193 " || ss -tuln 2>/dev/null | grep -q ":9193 "; then
        log_warning "포트 9193이 여전히 사용 중입니다"
    else
        log_success "포트 9193 정리됨"
    fi

    # 포트 3000 (Grafana) 확인
    if netstat -tuln 2>/dev/null | grep -q ":3000 " || ss -tuln 2>/dev/null | grep -q ":3000 "; then
        log_warning "포트 3000이 여전히 사용 중입니다"
    else
        log_success "포트 3000 정리됨"
    fi
}

# 시스템 정리
cleanup_system() {
    log_info "시스템 정리 중..."

    # systemd 데몬 재로드
    sudo systemctl daemon-reload

    # 패키지 캐시 정리 (선택적)
    case $OS in
        "amzn"|"centos"|"rhel")
            sudo dnf clean all &>/dev/null || true
            ;;
        "ubuntu")
            sudo apt-get clean &>/dev/null || true
            ;;
    esac

    log_success "시스템 정리 완료"
}

# 최종 상태 확인
verify_removal() {
    log_info "제거 상태 확인 중..."

    local issues=0

    # 바이너리 확인
    if command -v steampipe &> /dev/null; then
        log_warning "Steampipe 바이너리가 여전히 존재합니다"
        issues=$((issues + 1))
    fi

    if command -v grafana-server &> /dev/null; then
        log_warning "Grafana 바이너리가 여전히 존재합니다"
        issues=$((issues + 1))
    fi

    # 서비스 확인
    if systemctl list-unit-files | grep -q grafana-server; then
        log_warning "Grafana systemd 서비스가 여전히 등록되어 있습니다"
        issues=$((issues + 1))
    fi

    if [[ $issues -eq 0 ]]; then
        log_success "모든 컴포넌트가 성공적으로 제거되었습니다"
    else
        log_warning "$issues개의 컴포넌트가 완전히 제거되지 않았습니다"
    fi
}

# 메인 제거 함수
main() {
    echo "============================================================================="
    echo "                      🗑️  Steampipe + Grafana 제거 도구                   "
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
    confirm_uninstall

    echo ""
    log_info "제거 작업을 시작합니다..."
    echo ""

    remove_steampipe
    remove_grafana
    remove_generated_files
    check_port_cleanup
    cleanup_system
    verify_removal

    echo ""
    echo "============================================================================="
    echo "                              ✅ 제거 완료                                 "
    echo "============================================================================="
    echo ""
    echo "🎉 Steampipe와 Grafana가 성공적으로 제거되었습니다!"
    echo ""
    echo "📝 제거된 항목:"
    echo "   • Steampipe 바이너리 및 설정"
    echo "   • Grafana 서버 및 데이터"
    echo "   • 생성된 설정 파일들"
    echo "   • systemd 서비스 등록"
    echo ""
    echo "✅ 보존된 파일들:"
    echo "   • install-steampipe-grafana.sh (재설치용)"
    echo "   • verify-installation.sh (검증용)"
    echo "   • uninstall.sh (제거용)"
    echo "   • README.md (가이드)"
    echo "   • 대시보드 및 설정 템플릿 파일들"
    echo ""
    echo "🔄 재설치하려면:"
    echo "   ./install-steampipe-grafana.sh 스크립트를 다시 실행하세요"
    echo ""
    log_success "제거 작업이 완료되었습니다!"
}

# 스크립트 실행
main "$@"