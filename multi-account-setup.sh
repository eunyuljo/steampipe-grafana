#!/bin/bash

# =============================================================================
# Steampipe Multi-Account 설정 스크립트
# 여러 AWS 계정을 동시에 모니터링하기 위한 설정
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

# Steampipe 설정 디렉토리 생성
setup_steampipe_config() {
    log_info "Steampipe 다중 계정 설정 중..."

    # 설정 디렉토리 확인/생성
    mkdir -p ~/.steampipe/config

    # 기본 설정 백업
    if [[ -f ~/.steampipe/config/aws.spc ]]; then
        cp ~/.steampipe/config/aws.spc ~/.steampipe/config/aws.spc.backup.$(date +%Y%m%d_%H%M%S)
        log_info "기존 AWS 설정 백업 완료"
    fi
}

# Multi-Account 설정 생성
create_multi_account_config() {
    log_info "다중 계정 설정 파일 생성 중..."

    cat > ~/.steampipe/config/aws.spc << 'EOF'
# AWS Multi-Account Configuration
# 여러 AWS 계정을 동시에 모니터링하기 위한 설정

# 계정 A (메인 계정)
connection "aws_account_a" {
  plugin = "aws"

  # AWS Profile 사용 방법
  profile = "account-a"
  regions = ["ap-northeast-2", "us-east-1", "eu-west-1"]
}

# 계정 B (개발 계정)
connection "aws_account_b" {
  plugin = "aws"

  # AWS Profile 사용 방법
  profile = "account-b"
  regions = ["ap-northeast-2", "us-east-1"]
}

# 계정 C (스테이징 계정)
connection "aws_account_c" {
  plugin = "aws"

  # AWS Profile 사용 방법
  profile = "account-c"
  regions = ["ap-northeast-2"]
}

# Cross-Account Role 방식 (필요시 사용)
# connection "aws_cross_account" {
#   plugin = "aws"
#
#   # Role ARN 방식
#   role_arn = "arn:aws:iam::123456789012:role/SteampipeCrossAccountRole"
#   external_id = "unique-external-id"
#   regions = ["ap-northeast-2"]
# }

# 모든 계정을 통합하는 Aggregation 연결
connection "aws_all" {
  plugin      = "aws"
  type        = "aggregator"
  connections = ["aws_account_a", "aws_account_b", "aws_account_c"]
}

EOF

    log_success "다중 계정 설정 파일 생성 완료: ~/.steampipe/config/aws.spc"
}

# AWS Profiles 존재 확인
check_aws_profiles() {
    log_info "AWS Profiles 확인 중..."

    local profiles_found=0

    # 설정된 프로필 확인
    if aws configure list-profiles 2>/dev/null; then
        log_success "AWS Profiles 감지됨"

        # 각 프로필별 계정 ID 확인
        for profile in $(aws configure list-profiles 2>/dev/null); do
            log_info "프로필 '$profile' 확인 중..."
            if aws sts get-caller-identity --profile $profile --output text --query 'Account' 2>/dev/null; then
                local account_id=$(aws sts get-caller-identity --profile $profile --output text --query 'Account' 2>/dev/null)
                log_success "  └─ 프로필: $profile, 계정 ID: $account_id"
                profiles_found=$((profiles_found + 1))
            else
                log_warning "  └─ 프로필: $profile (접근 불가 - 자격 증명 확인 필요)"
            fi
        done

        if [[ $profiles_found -gt 1 ]]; then
            log_success "$profiles_found개의 유효한 AWS 계정 감지됨"
        else
            log_warning "1개의 계정만 감지됨. 추가 계정 설정이 필요합니다."
        fi
    else
        log_error "AWS CLI가 설정되지 않았습니다."
        show_aws_setup_guide
    fi
}

# AWS 설정 가이드 출력
show_aws_setup_guide() {
    log_info "AWS 다중 계정 설정 가이드:"
    echo ""
    echo "1️⃣  추가 AWS 계정 프로필 설정:"
    echo "   aws configure --profile account-production"
    echo "   aws configure --profile account-development"
    echo "   aws configure --profile account-staging"
    echo ""
    echo "2️⃣  각 계정의 Access Key 설정:"
    echo "   - Access Key ID: [계정별 액세스 키]"
    echo "   - Secret Access Key: [계정별 시크릿 키]"
    echo "   - Default region: ap-northeast-2"
    echo ""
    echo "3️⃣  계정 접근 권한 확인:"
    echo "   aws sts get-caller-identity --profile account-production"
    echo ""
}

# Steampipe 재시작
restart_steampipe() {
    log_info "Steampipe 서비스 재시작 중..."

    # 기존 서비스 중지
    steampipe service stop || true

    # 잠시 대기
    sleep 3

    # 서비스 시작
    steampipe service start

    # 연결 테스트
    log_info "다중 계정 연결 테스트 중..."
    sleep 5

    if steampipe query "select connection_name, count(*) as instance_count from aws_all.aws_ec2_instance group by connection_name" --output table; then
        log_success "다중 계정 연결 테스트 성공!"
    else
        log_warning "연결 테스트 실패 - 설정을 확인하세요"
        show_troubleshooting_guide
    fi
}

# 문제 해결 가이드
show_troubleshooting_guide() {
    log_info "문제 해결 가이드:"
    echo ""
    echo "🔧 일반적인 문제들:"
    echo ""
    echo "1️⃣  AWS Profile이 없는 경우:"
    echo "   aws configure --profile [profile-name]"
    echo ""
    echo "2️⃣  권한 부족 오류:"
    echo "   - IAM 사용자에게 ReadOnly 권한 부여"
    echo "   - 최소 권한: ec2:Describe*, rds:Describe*, s3:List*, iam:List*"
    echo ""
    echo "3️⃣  특정 계정이 접근되지 않는 경우:"
    echo "   aws sts get-caller-identity --profile [problem-profile]"
    echo ""
    echo "4️⃣  Steampipe 로그 확인:"
    echo "   steampipe service status"
    echo "   tail -f ~/.steampipe/logs/plugin-aws.log"
    echo ""
}

# 사용 예시 출력
show_usage_examples() {
    log_success "다중 계정 설정 완료!"
    echo ""
    log_info "🎯 사용 예시:"
    echo ""
    echo "📊 모든 계정의 EC2 인스턴스 조회:"
    echo "   steampipe query \"SELECT connection_name as account, instance_id, instance_state FROM aws_all.aws_ec2_instance\""
    echo ""
    echo "📊 계정별 리소스 수 요약:"
    echo "   steampipe query \"SELECT connection_name, count(*) FROM aws_all.aws_ec2_instance GROUP BY connection_name\""
    echo ""
    echo "📊 특정 계정만 조회:"
    echo "   steampipe query \"SELECT * FROM aws_account_a.aws_ec2_instance\""
    echo ""
    echo "📊 계정별 보안 그룹 조회:"
    echo "   steampipe query \"SELECT connection_name, group_name, group_id FROM aws_all.aws_vpc_security_group\""
    echo ""
    log_info "💡 Grafana 대시보드에서도 aws_all.* 테이블을 사용하여 모든 계정을 통합 조회할 수 있습니다!"
}

# 메인 함수
main() {
    echo "============================================================================="
    echo "                    🌐 Steampipe Multi-Account 설정                         "
    echo "============================================================================="
    echo ""

    check_aws_profiles
    setup_steampipe_config
    create_multi_account_config
    restart_steampipe
    show_usage_examples

    echo ""
    echo "============================================================================="
    echo "                          ✅ 설정 완료!                                    "
    echo "============================================================================="
}

# 스크립트 실행
main "$@"