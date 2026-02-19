# =============================================================================
# 기존 connection "aws" 블록은 그대로 유지하고,
# 아래 설정들을 ~/.steampipe/config/aws.spc 파일 끝에 추가하세요
# =============================================================================

# Default Profile 기반 연결 (메인 계정)
connection "aws_default" {
  plugin = "aws"
  profile = "default"
  regions = ["ap-northeast-2", "us-east-1", "ap-southeast-1"]

  # 메인 계정용 설정
  max_error_retry_attempts = 9
  min_error_retry_delay = 25
}

# Estaid Profile 기반 연결 (default와 동일한 계정이지만 별도 관리)
connection "aws_estaid" {
  plugin = "aws"
  profile = "estaid"
  regions = ["ap-northeast-2", "us-east-1"]

  # Estaid 전용 설정
  max_error_retry_attempts = 9
  min_error_retry_delay = 25
}

# Test-FNF Profile 기반 연결 (별도 계정)
connection "aws_test_fnf" {
  plugin = "aws"
  profile = "test-fnf"
  regions = ["ap-northeast-2", "us-west-2"]

  # 테스트 계정용 설정
  max_error_retry_attempts = 5
  min_error_retry_delay = 50

  # 테스트 계정에서는 일부 에러 무시 (권한 제한 등)
  ignore_error_codes = ["AccessDenied", "UnauthorizedOperation"]
}

# =============================================================================
# Aggregator 설정 (선택사항)
# =============================================================================

# 모든 Profile 통합 조회용
connection "aws_all_profiles" {
  plugin      = "aws"
  type        = "aggregator"
  connections = ["aws_default", "aws_estaid", "aws_test_fnf"]
}

# 메인 계정들만 (default + estaid - 동일 계정이므로 용도별 분리)
connection "aws_main_accounts" {
  plugin      = "aws"
  type        = "aggregator"
  connections = ["aws_default", "aws_estaid"]
}