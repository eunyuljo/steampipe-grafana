# 기존 기본 connection (현재 사용중인 설정 유지)
connection "aws" {
  plugin = "aws"
  # 기존 설정 그대로 유지
  # profile이 지정되지 않으면 default profile 사용
}

# =============================================================================
# Profile별 분리된 Connection 설정
# =============================================================================

# Production 계정
connection "aws_production" {
  plugin = "aws"
  profile = "account-production"  # AWS CLI profile 이름
  regions = ["ap-northeast-2", "us-east-1", "eu-west-1"]

  # Production 환경에 맞는 설정
  max_error_retry_attempts = 9
  min_error_retry_delay = 25
}

# Development 계정
connection "aws_development" {
  plugin = "aws"
  profile = "account-development"  # AWS CLI profile 이름
  regions = ["ap-northeast-2", "us-east-1"]

  # Development 환경 설정
  max_error_retry_attempts = 5
  min_error_retry_delay = 50
}

# Staging 계정
connection "aws_staging" {
  plugin = "aws"
  profile = "account-staging"  # AWS CLI profile 이름
  regions = ["ap-northeast-2"]

  # Staging 환경 설정
  max_error_retry_attempts = 3
  min_error_retry_delay = 100
}

# Management/Billing 계정 (필요시)
connection "aws_management" {
  plugin = "aws"
  profile = "account-management"
  regions = ["us-east-1"]  # Billing 정보는 보통 us-east-1
}

# =============================================================================
# 선택적 Aggregator (통합 조회용)
# =============================================================================

# 모든 계정 통합 (기존 aws connection 제외)
connection "aws_all_profiles" {
  plugin      = "aws"
  type        = "aggregator"
  connections = ["aws_production", "aws_development", "aws_staging"]
}

# Production + Staging만 (운영 환경)
connection "aws_prod_staging" {
  plugin      = "aws"
  type        = "aggregator"
  connections = ["aws_production", "aws_staging"]
}