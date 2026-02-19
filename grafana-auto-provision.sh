#!/bin/bash

# =============================================================================
# Grafana 대시보드 자동 프로비저닝 스크립트
# JSON 임포트 후 데이터소스 자동 연결
# =============================================================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Grafana 서비스 확인
check_grafana_service() {
    log_info "Grafana 서비스 상태 확인 중..."

    if ! curl -s -f http://localhost:3000/api/health &>/dev/null; then
        log_error "Grafana 서비스에 접근할 수 없습니다"
        log_info "다음 명령으로 Grafana를 시작하세요:"
        echo "  sudo systemctl start grafana-server"
        exit 1
    fi

    log_success "Grafana 서비스 정상 확인"
}

# 기존 데이터소스 확인 및 생성
setup_datasource() {
    log_info "데이터소스 설정 중..."

    # 기존 Steampipe 데이터소스 확인
    local datasource_check
    datasource_check=$(curl -s -u admin:admin http://localhost:3000/api/datasources/name/Steampipe 2>/dev/null)

    if echo "$datasource_check" | grep -q '"name":"Steampipe"'; then
        log_success "Steampipe 데이터소스가 이미 존재합니다"
        # UID 추출
        DATASOURCE_UID=$(echo "$datasource_check" | grep -o '"uid":"[^"]*"' | cut -d'"' -f4)
        log_info "데이터소스 UID: $DATASOURCE_UID"
    else
        log_info "새로운 Steampipe 데이터소스 생성 중..."

        # Steampipe 패스워드 가져오기
        local steampipe_password
        steampipe_password=$(steampipe service status --show-password 2>/dev/null | grep "Password:" | awk '{print $2}' || echo "")

        if [[ -z "$steampipe_password" ]]; then
            log_warning "Steampipe 패스워드를 자동으로 가져올 수 없습니다"
            steampipe_password=""
        fi

        # 데이터소스 JSON 생성
        local datasource_json
        datasource_json=$(cat <<EOF
{
  "name": "Steampipe",
  "type": "postgres",
  "access": "proxy",
  "url": "localhost:9193",
  "database": "steampipe",
  "user": "steampipe",
  "password": "$steampipe_password",
  "jsonData": {
    "sslmode": "disable",
    "postgresVersion": 1300
  },
  "isDefault": true
}
EOF
)

        # 데이터소스 생성
        local response
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -u admin:admin \
            -d "$datasource_json" \
            http://localhost:3000/api/datasources 2>/dev/null)

        if echo "$response" | grep -q '"message":"Datasource added"'; then
            log_success "Steampipe 데이터소스 생성 완료"
            # 새로 생성된 데이터소스 UID 가져오기
            DATASOURCE_UID=$(echo "$response" | grep -o '"uid":"[^"]*"' | cut -d'"' -f4)
            log_info "새 데이터소스 UID: $DATASOURCE_UID"
        else
            log_error "데이터소스 생성 실패: $response"
            exit 1
        fi
    fi
}

# JSON 파일에서 데이터소스 UID 업데이트
update_dashboard_json() {
    local json_file=$1
    local output_file=$2

    log_info "$json_file 대시보드 JSON 업데이트 중..."

    if [[ ! -f "$json_file" ]]; then
        log_warning "$json_file 파일이 존재하지 않습니다"
        return 1
    fi

    # 출력 파일의 디렉토리 생성
    local output_dir=$(dirname "$output_file")
    mkdir -p "$output_dir"

    # 데이터소스 UID 치환
    sed "s/\"uid\": \"steampipe\"/\"uid\": \"$DATASOURCE_UID\"/g" "$json_file" > "$output_file"

    log_success "$output_file 생성 완료"
}

# 대시보드 임포트
import_dashboard() {
    local json_file=$1
    local dashboard_name=$2

    log_info "$dashboard_name 대시보드 임포트 중..."

    if [[ ! -f "$json_file" ]]; then
        log_warning "$json_file 파일이 존재하지 않습니다"
        return 1
    fi

    # 대시보드 JSON 읽기
    local dashboard_json
    dashboard_json=$(cat "$json_file")

    # 임포트 요청
    local import_payload
    import_payload=$(cat <<EOF
{
  "dashboard": $dashboard_json,
  "overwrite": true,
  "inputs": [
    {
      "name": "DS_STEAMPIPE",
      "type": "datasource",
      "pluginId": "postgres",
      "value": "$DATASOURCE_UID"
    }
  ]
}
EOF
)

    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u admin:admin \
        -d "$import_payload" \
        http://localhost:3000/api/dashboards/import 2>/dev/null)

    if echo "$response" | grep -q '"imported":true'; then
        log_success "$dashboard_name 대시보드 임포트 완료"
        local dashboard_url
        dashboard_url=$(echo "$response" | grep -o '"importedUrl":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$dashboard_url" ]]; then
            log_info "대시보드 URL: http://localhost:3000$dashboard_url"
        fi
    else
        log_error "$dashboard_name 대시보드 임포트 실패: $response"
    fi
}

# 메인 실행 함수
main() {
    echo "============================================================================="
    echo "                    🔧 Grafana 대시보드 자동 프로비저닝                      "
    echo "============================================================================="
    echo ""

    check_grafana_service
    setup_datasource

    # 사용 가능한 대시보드 JSON 파일들 (dashboards 폴더에서)
    declare -A dashboards=(
        ["dashboards/grafana-ec2-v12-optimized.json"]="EC2 종합 모니터링 (v12.3.3 최적화)"
        ["dashboards/grafana-security-timeline-dashboard.json"]="보안 이벤트 시간별 추이"
        ["dashboards/grafana-iam-security-dashboard.json"]="IAM 보안 모니터링"
        ["dashboards/grafana-s3-security-dashboard.json"]="S3 보안 모니터링"
        ["dashboards/grafana-network-security-dashboard.json"]="네트워크 보안 모니터링"
        ["dashboards/grafana-encryption-compliance-dashboard.json"]="암호화 및 키 관리 컴플라이언스"
        ["dashboards/grafana-risk-assessment-dashboard.json"]="위험 평가 및 컴플라이언스"
        ["dashboards/grafana-security-incident-dashboard.json"]="보안 인시던트 대응 센터"
        ["dashboards/grafana-security-kpi-dashboard.json"]="보안 운영 KPI"
    )

    # 각 대시보드 처리
    for json_file in "${!dashboards[@]}"; do
        dashboard_name="${dashboards[$json_file]}"

        if [[ -f "$json_file" ]]; then
            # 임시 파일 생성 (UID 치환됨)
            temp_file="temp_$(basename "$json_file")"
            update_dashboard_json "$json_file" "$temp_file"

            # 대시보드 임포트
            import_dashboard "$temp_file" "$dashboard_name"

            # 임시 파일 삭제
            rm -f "$temp_file"
        else
            log_warning "$json_file 파일을 찾을 수 없습니다"
        fi
    done

    echo ""
    log_success "모든 대시보드 프로비저닝 완료!"
    log_info "Grafana 접속: http://localhost:3000 (admin/admin)"
}

# 스크립트 실행
main "$@"