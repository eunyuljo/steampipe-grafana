#!/bin/bash

# =============================================================================
# Steampipe + Grafana 설치 검증 스크립트
# 설치된 환경이 올바르게 작동하는지 확인합니다
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
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 전역 변수
FAILED_CHECKS=0
TOTAL_CHECKS=0

# 체크 함수
check_service() {
    local service_name=$1
    local description=$2

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if command -v $service_name &> /dev/null; then
        log_success "$description 설치됨"
    else
        log_error "$description 설치되지 않음"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# 네트워크 포트 체크 함수
check_port() {
    local port=$1
    local service=$2

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        log_success "$service (포트 $port) 실행 중"
    elif ss -tuln 2>/dev/null | grep -q ":$port "; then
        log_success "$service (포트 $port) 실행 중"
    else
        log_error "$service (포트 $port) 실행되지 않음"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# HTTP 서비스 체크 함수
check_http_service() {
    local url=$1
    local service=$2

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if curl -s -f -o /dev/null "$url"; then
        log_success "$service HTTP 서비스 응답 정상"
    else
        local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        if [[ $http_code == "302" || $http_code == "200" ]]; then
            log_success "$service HTTP 서비스 응답 정상 (HTTP $http_code)"
        else
            log_error "$service HTTP 서비스 응답 없음 (HTTP $http_code)"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
        fi
    fi
}

# 데이터베이스 연결 체크 함수
check_database_connection() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    log_info "Steampipe 데이터베이스 연결 테스트 중..."

    if steampipe query "SELECT 1 as test" &>/dev/null; then
        log_success "Steampipe 데이터베이스 연결 성공"
    else
        log_error "Steampipe 데이터베이스 연결 실패"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# AWS 연결 체크 함수
check_aws_connection() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    log_info "AWS 연결 테스트 중..."

    if steampipe query "SELECT count(*) FROM aws_ec2_instance" &>/dev/null; then
        local instance_count=$(steampipe query "SELECT count(*) FROM aws_ec2_instance" --output csv 2>/dev/null | tail -n 1 | cut -d',' -f1)
        log_success "AWS 연결 성공 (EC2 인스턴스: $instance_count개)"
    else
        log_warning "AWS 연결 실패 - AWS 자격 증명을 확인하세요"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# 시스템 서비스 체크 함수
check_systemd_service() {
    local service=$1
    local description=$2

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if systemctl is-active --quiet $service; then
        log_success "$description systemd 서비스 실행 중"
    else
        log_error "$description systemd 서비스 실행되지 않음"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# 파일 존재 체크 함수
check_file_exists() {
    local file_path=$1
    local description=$2

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [[ -f "$file_path" ]]; then
        log_success "$description 파일 존재함"
    else
        log_error "$description 파일이 존재하지 않음: $file_path"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# 메인 검증 함수
main() {
    echo "============================================================================="
    echo "                     🔍 Steampipe + Grafana 설치 검증                      "
    echo "============================================================================="
    echo ""

    log_info "설치 검증을 시작합니다..."
    echo ""

    # 1. 바이너리 설치 확인
    log_info "1. 필수 바이너리 설치 확인"
    check_service "steampipe" "Steampipe"
    check_service "grafana-server" "Grafana Server"
    echo ""

    # 2. 시스템 서비스 상태 확인
    log_info "2. 시스템 서비스 상태 확인"
    check_systemd_service "grafana-server" "Grafana"
    echo ""

    # 3. 네트워크 포트 확인
    log_info "3. 네트워크 포트 상태 확인"
    check_port "9193" "Steampipe Database"
    check_port "3000" "Grafana Web Interface"
    echo ""

    # 4. HTTP 서비스 응답 확인
    log_info "4. HTTP 서비스 응답 확인"
    check_http_service "http://localhost:3000" "Grafana"
    echo ""

    # 5. 데이터베이스 연결 확인
    log_info "5. 데이터베이스 연결 확인"
    check_database_connection
    echo ""

    # 6. AWS 연결 확인
    log_info "6. AWS 서비스 연결 확인"
    check_aws_connection
    echo ""

    # 7. 설정 파일 확인
    log_info "7. 설정 파일 존재 확인"
    check_file_exists ".env.example" "환경 설정 템플릿"
    check_file_exists "dashboards/grafana-aws-infra-comprehensive.json" "통합 인프라 대시보드 (메인)"
    check_file_exists "dashboards/grafana-ec2-v12-optimized.json" "EC2 대시보드 (v12.3.3 최적화)"
    check_file_exists "dashboards/grafana-backup-monitoring-dashboard.json" "백업 모니터링 전용 대시보드"
    check_file_exists "grafana-datasource.yaml" "Grafana 데이터소스 설정"
    check_file_exists "claude.md" "프로젝트 문서"
    echo ""

    # 결과 출력
    echo "============================================================================="
    echo "                              📊 검증 결과                                  "
    echo "============================================================================="

    local success_count=$((TOTAL_CHECKS - FAILED_CHECKS))

    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${GREEN}🎉 모든 검증 통과! ($success_count/$TOTAL_CHECKS)${NC}"
        echo ""
        echo "✅ 설치가 완벽하게 완료되었습니다!"
        echo "🚀 다음 단계:"
        echo "   1. 브라우저에서 http://localhost:3000 접속"
        echo "   2. admin/admin으로 로그인"
        echo "   3. Steampipe 데이터소스가 자동 설정됨"
        echo "   4. 대시보드 JSON 파일 임포트"
        exit 0
    else
        echo -e "${RED}❌ 일부 검증 실패 ($success_count/$TOTAL_CHECKS 통과, $FAILED_CHECKS 실패)${NC}"
        echo ""
        echo "🔧 문제 해결 방법:"
        echo "   • 재설치: ./install-steampipe-grafana.sh"
        echo "   • AWS 자격 증명 확인: aws sts get-caller-identity"
        echo "   • 로그 확인: sudo journalctl -u grafana-server -f"
        exit 1
    fi
}

# 권한 체크
if [[ $EUID -eq 0 ]]; then
    log_error "이 스크립트는 루트 사용자로 실행하지 마세요."
    exit 1
fi

# 스크립트 실행
main "$@"