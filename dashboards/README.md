# 🛡️ AWS 보안 모니터링 대시보드 모음

이 폴더에는 Steampipe + Grafana를 활용한 AWS 보안 모니터링 대시보드들이 포함되어 있습니다.

## 📊 대시보드 목록

### 1. **기본 모니터링**
- `grafana-dashboard-simple.json` - EC2 기본 모니터링 (간단한 버전)
- `grafana-aws-infra-comprehensive.json` - 🏢 AWS 통합 인프라 모니터링 (메인)
- `grafana-ec2-v12-optimized.json` - 🖥️ EC2 전용 모니터링 (v12.3.3 최적화)
- `grafana-backup-monitoring-dashboard.json` - 💾 백업 모니터링 전용

### 2. **🌐 다중 계정 모니터링**

#### 📊 통합 다중 계정 대시보드
- **파일**: `grafana-multi-account-dashboard.json`
- **대상**: 다중 AWS 계정 운영팀, DevOps 엔지니어
- **기능**:
  - 계정별 리소스 분포 현황 (EC2, RDS, S3)
  - 계정별 보안 위험 요소 비교
  - 계정 간 비용 및 리소스 사용량 비교
  - 계정별 리전 사용 현황
  - Cross-Account 리소스 분석

#### 🔧 Profile별 독립 대시보드 생성 방법

다중 계정 환경에서는 각 AWS Profile별로 독립된 대시보드를 생성할 수 있습니다:

**필수 사전 설정:**
```bash
# ~/.steampipe/config/aws.spc 파일에 Profile별 Connection 추가
connection "aws_production" {
  plugin = "aws"
  profile = "production"
  regions = ["ap-northeast-2", "us-east-1"]
}

connection "aws_development" {
  plugin = "aws"
  profile = "development"
  regions = ["ap-northeast-2"]
}

connection "aws_staging" {
  plugin = "aws"
  profile = "staging"
  regions = ["ap-northeast-2"]
}
```

**계정별 대시보드 쿼리 예시:**
```sql
-- Production 계정 전용 EC2 조회
SELECT instance_id, instance_type, instance_state
FROM aws_production.aws_ec2_instance

-- Development 계정 전용 RDS 조회
SELECT db_instance_identifier, engine, db_instance_status
FROM aws_development.aws_rds_db_instance

-- 계정 간 비교 쿼리
SELECT 'Production' as account, count(*) FROM aws_production.aws_ec2_instance
UNION ALL
SELECT 'Development' as account, count(*) FROM aws_development.aws_ec2_instance
UNION ALL
SELECT 'Staging' as account, count(*) FROM aws_staging.aws_ec2_instance
```

### 3. **기본 보안 모니터링 시리즈**

#### 🕐 시간별 보안 이벤트 추이
- **파일**: `grafana-security-timeline-dashboard.json`
- **기능**:
  - 일별/시간별 인스턴스 생성 패턴
  - 24시간 내 위험 지표 알람
  - 보안그룹 사용 패턴 변화
  - 보안 이벤트 타임라인

#### 🔐 IAM 보안 모니터링
- **파일**: `grafana-iam-security-dashboard.json`
- **기능**:
  - 90일 이상 미사용 계정 탐지
  - 사용자 활동 패턴 분석
  - IAM 사용자 위험도 평가

#### 🪣 S3 보안 모니터링
- **파일**: `grafana-s3-security-dashboard.json`
- **기능**:
  - 퍼블릭 액세스 허용 버킷 경고
  - 버전 관리 비활성화 버킷 탐지
  - S3 버킷 보안 위험도 평가

#### 🌐 네트워크 보안 모니터링
- **파일**: `grafana-network-security-dashboard.json`
- **기능**:
  - SSH/RDP 전체 오픈 보안그룹 경고
  - 0.0.0.0/0 오픈 포트 분석
  - VPC별 인스턴스 분포
  - 위험한 보안그룹 상세 분석

### 3. **🛡️ 보안 실무자용 전문 대시보드 시리즈**

#### 🔐 암호화 및 키 관리 컴플라이언스
- **파일**: `grafana-encryption-compliance-dashboard.json`
- **대상**: 보안 실무자, 컴플라이언스 담당자
- **기능**:
  - KMS 키 상태 및 생명주기 관리
  - 삭제 예정 암호화 키 경고
  - 액세스 키 연령 및 위험도 평가 (90일/365일 기준)
  - 사용자별 액세스 키 수 분석
  - 암호화 키 사용 패턴 모니터링

#### ⚠️ 위험 평가 및 컴플라이언스
- **파일**: `grafana-risk-assessment-dashboard.json`
- **대상**: 보안 매니저, 위험 관리 담당자
- **기능**:
  - EC2/S3 보안 컴플라이언스 점수 (게이지 형태)
  - 위험 요소별 실시간 알람 패널
  - 일별 보안 위험 요소 추이 분석
  - 인스턴스 위험도 상세 평가 매트릭스
  - 종합 위험도 스코어링 시스템

#### 🚨 보안 인시던트 대응 센터
- **파일**: `grafana-security-incident-dashboard.json`
- **대상**: SOC 분석가, 인시던트 대응팀
- **기능**:
  - 1시간 내 긴급 이벤트 모니터링
  - 24시간 내 새 액세스 키 생성 추적
  - 업무시간 외 비정상 활동 탐지
  - 시간대별 보안 이벤트 패턴 분석
  - 실시간 보안 인시던트 상세 로그

#### 📈 보안 운영 KPI
- **파일**: `grafana-security-kpi-dashboard.json`
- **대상**: 보안 운영팀, 경영진 보고용
- **기능**:
  - 네트워크 격리/데이터 보호/인증 보안 지수
  - 보안 KPI 30일 추이 분석
  - 일별 위험도 분포 스택 차트
  - 보안 영역별 종합 점수표
  - 경영진 대시보드 (요약 지표)

## 🚀 사용 방법

### 1. 단일 계정 대시보드 사용

#### 개별 대시보드 임포트
```bash
# Grafana 접속
http://localhost:3000

# 대시보드 임포트
1. + (Create) → Import 클릭
2. JSON 파일 업로드 또는 내용 복사
3. 데이터소스를 "Steampipe"로 선택
4. Import 클릭
```

#### 자동 일괄 임포트 (권장)
```bash
# 상위 디렉토리에서 자동 프로비저닝 스크립트 실행
cd ..
./grafana-auto-provision.sh
```

### 2. 다중 계정 대시보드 설정

#### 사전 준비: AWS Profile 설정
```bash
# AWS CLI Profile 생성
aws configure --profile production
aws configure --profile development
aws configure --profile staging

# Profile 목록 확인
aws configure list-profiles
```

#### Steampipe 다중 계정 설정
```bash
# 다중 계정 자동 설정 스크립트 실행
cd ..
./multi-account-setup.sh

# 또는 수동으로 ~/.steampipe/config/aws.spc 파일 수정
```

#### 다중 계정 대시보드 임포트
1. **통합 대시보드**: `grafana-multi-account-dashboard.json`
   - 모든 계정을 한 번에 모니터링
   - `aws_all_profiles` aggregator 사용

2. **계정별 독립 대시보드**: 기존 대시보드 복사 후 쿼리 수정
   - `FROM aws.table_name` → `FROM aws_production.table_name`
   - `FROM aws.table_name` → `FROM aws_development.table_name`
   - `FROM aws.table_name` → `FROM aws_staging.table_name`

#### 다중 계정 연결 테스트
```bash
# 각 계정별 연결 확인
steampipe query "SELECT count(*) FROM aws_production.aws_ec2_instance"
steampipe query "SELECT count(*) FROM aws_development.aws_ec2_instance"
steampipe query "SELECT count(*) FROM aws_staging.aws_ec2_instance"

# 통합 조회 테스트
steampipe query "SELECT connection_name, count(*) FROM aws_all_profiles.aws_ec2_instance GROUP BY connection_name"
```

## 🔧 문제 해결

### 단일 계정 "No Data" 문제:
1. **데이터소스 확인**: Settings → Data Sources에서 Steampipe 연결 상태 확인
2. **패널별 수정**: 각 패널 Edit → Data source를 "Steampipe"로 변경
3. **가이드 참조**: 상위 디렉토리의 `fix-no-data.md` 파일 참조

### 다중 계정 문제 해결:

#### 1. 특정 계정 "No Data" 문제:
```bash
# AWS Profile 연결 확인
aws sts get-caller-identity --profile production
aws sts get-caller-identity --profile development

# Steampipe Connection 테스트
steampipe query "SELECT 1 FROM aws_production.aws_ec2_instance LIMIT 1"
steampipe query "SELECT 1 FROM aws_development.aws_ec2_instance LIMIT 1"
```

#### 2. Connection 설정 문제:
```bash
# Connection 목록 확인
steampipe query ".inspect"

# 특정 Connection 상태 확인
steampipe service status

# Connection 재설정
steampipe service restart
```

#### 3. AWS 권한 문제:
- **증상**: 일부 계정에서만 데이터가 나오지 않음
- **해결**:
  ```bash
  # 각 Profile별 IAM 권한 확인
  aws iam list-attached-user-policies --user-name [username] --profile production
  aws iam list-attached-user-policies --user-name [username] --profile development
  ```

#### 4. 빠른 수정 방법:
```bash
# 데이터소스 UID 확인 후 JSON 파일 수정
sed -i 's/"uid": "steampipe"/"uid": "실제_UID"/g' *.json

# 다중 계정용 쿼리 일괄 변경
sed -i 's/FROM aws\./FROM aws_production\./g' grafana-production-dashboard.json
sed -i 's/FROM aws\./FROM aws_development\./g' grafana-development-dashboard.json
```

## 🎯 보안 모니터링 포인트

### 단일 계정 모니터링

#### 🔴 Critical 알람
- SSH/RDP 포트가 전체에 열린 보안그룹
- 퍼블릭 액세스가 허용된 S3 버킷
- 90일 이상 미사용 IAM 계정

#### 🟡 Medium 위험
- 버전 관리가 비활성화된 S3 버킷
- 과도한 인바운드 규칙을 가진 보안그룹
- 비정상 시간대 인스턴스 생성

#### 🟢 정상 모니터링
- 전체 리소스 현황
- 시간대별 활동 패턴
- VPC별 분산 상태

### 🌐 다중 계정 모니터링

#### 🔴 Critical 다중 계정 알람
- **Cross-Account 보안 위험**: 계정별 보안 정책 불일치
- **계정 간 권한 문제**: 과도한 Cross-Account 권한
- **통합 모니터링 실패**: 특정 계정의 연결 장애

#### 🟡 Medium 다중 계정 위험
- **리소스 분산 불균형**: 특정 계정에 리소스 집중
- **계정별 태그 정책 불일치**: 거버넌스 정책 위반
- **백업 정책 차이**: 계정 간 백업 설정 불일치

#### 🟢 정상 다중 계정 모니터링
- **계정별 리소스 현황**: 모든 계정의 균형 잡힌 분포
- **통합 보안 상태**: 모든 계정에서 일관된 보안 정책
- **Cross-Account 접근 추적**: 계정 간 정상적인 리소스 접근

## 📈 대시보드 확장

### 단일 계정 대시보드 추가:
1. Steampipe AWS 플러그인의 테이블 확인: `steampipe query ".tables aws_*"`
2. 보안 관련 쿼리 개발
3. Grafana에서 패널 생성 후 JSON Export
4. 이 폴더에 추가

### 다중 계정 대시보드 생성:
1. **기존 대시보드 복제**: 단일 계정 대시보드를 기반으로 복사
2. **Connection 변경**: 쿼리에서 `aws.` → `aws_[profile].`로 수정
3. **제목 수정**: 대시보드 제목에 계정명 포함
4. **변수 활용**: Grafana Variable로 계정 선택 기능 추가

### 다중 계정 쿼리 패턴:
```sql
-- 단일 계정 쿼리
SELECT instance_id FROM aws.aws_ec2_instance

-- 특정 계정 쿼리
SELECT instance_id FROM aws_production.aws_ec2_instance

-- 통합 계정 쿼리 (connection_name 포함)
SELECT connection_name, instance_id FROM aws_all_profiles.aws_ec2_instance

-- 계정 간 비교 쿼리
SELECT
  'Production' as account, count(*) as instances
FROM aws_production.aws_ec2_instance
UNION ALL
SELECT
  'Development' as account, count(*) as instances
FROM aws_development.aws_ec2_instance
```

### Grafana Variable 활용:
```
Name: account_connection
Type: Custom
Values: aws_production,aws_development,aws_staging
Query에서 사용: FROM ${account_connection}.aws_ec2_instance
```

---

💡 **단일 계정 팁**: 모든 대시보드는 동일한 Steampipe 데이터소스를 사용하므로, 한 번 설정하면 모든 대시보드에서 활용 가능합니다!

🌐 **다중 계정 팁**: Profile별 Connection을 설정하면 계정별 독립 모니터링과 통합 모니터링을 동시에 사용할 수 있습니다!