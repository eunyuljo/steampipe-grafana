# Steampipe + Grafana AWS 모니터링 시스템

AWS 리소스를 실시간으로 모니터링할 수 있는 Steampipe와 Grafana 통합 환경을 **완전 자동화**로 구축할 수 있는 도구입니다.

## 🚀 빠른 시작

### 원클릭 설치
```bash
# 자동 설치 실행
./install-steampipe-grafana.sh

# 설치 검증
./verify-installation.sh

# 🏢 통합 인프라 대시보드 + 보안 대시보드 전체 설치
./grafana-auto-provision.sh

# 웹 접속: http://localhost:3000 (admin/admin)

# 참고 사항 
수행되는 스크립트는 위 기본 admin / admin 접속 정보를 바탕으로 작성되어있음.
따라서 웹 접속 이후 패스워드를 변경하게 되는데 그 패스워드를 따르도록 수정하거나 다시 admin 으로 변경한다.

```

## 📋 시스템 요구사항

### 지원 운영체제
- ✅ Amazon Linux 2023
- ✅ Ubuntu 20.04+
- ✅ CentOS/RHEL 8+

### Python 환경
- ✅ Python 3.10+ (필수)
- ✅ pyenv 권장 (버전 관리용)
- ✅ pip3 (선택사항)

### AWS 자격 증명
다음 중 하나의 방법으로 설정:
- AWS CLI: `aws configure`
- IAM 역할 (EC2에서 실행 시)
- 환경 변수: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

## 🎯 자동화 기능

### ✅ 완전 자동 설치
- OS 자동 감지 및 패키지 설치
- Steampipe v2.3.2 자동 설치
- AWS 플러그인 자동 설치
- **Grafana v12.3.3 최신 버전 설치** (최신 기능 제공)
- **🆕 데이터소스 자동 설정** (API 활용)
- **🆕 v12.3.3 최적화 대시보드** 자동 임포트

### ✅ 스마트 검증
- 12개 항목 자동 체크
- 실패 시 문제 해결 가이드 제공

### ✅ 안전한 제거
- 컴포넌트만 제거, 스크립트는 보존
- 재설치 가능

## 📊 기본 제공 대시보드

### 🏢 AWS 통합 인프라 모니터링 (메인 대시보드)
**AWS 인프라 전체를 모니터링하는 종합 통합 대시보드**

#### 📈 인프라 현황 요약 (8개 통계)
- 🖥️ **EC2 인스턴스** / 💾 **RDS 인스턴스** / 🪣 **S3 버킷** / ⚡ **Lambda 함수**
- 🌐 **VPC 네트워크** / ⚖️ **로드밸런서** / 👤 **IAM 사용자** / 🌍 **활성 리전**

#### 🚨 인프라 알림 및 위험 요소 (6개 위험 지표)
- ⏸️ **중지된 인스턴스** (비용 절감 기회)
- 🔓 **퍼블릭 RDS** (보안 위험)
- 🔐 **미암호화 EBS** (보안 위험)
- 🏷️ **미태그 리소스** (관리 위험)
- 🚨 **SSH 전체 오픈** (높은 위험)
- ⚠️ **루트 액세스 키** (최고 위험)

#### 📈 리전별 리소스 분포
- 🌍 **EC2 인스턴스 리전별 분포**
- 💾 **RDS 인스턴스 리전별 분포**

#### 🔍 리소스 상세 현황
- 💻 **EC2 인스턴스 타입별 분포** (상위 10개)
- 🗄️ **RDS 엔진별 분포**

#### 💾 백업 및 복구 현황
- 📀 **EBS 스냅샷** - 완료된 EBS 스냅샷 수
- 🔄 **RDS 자동 백업** - 자동 백업 활성화된 RDS 수
- 📅 **최근 백업** - 7일 내 생성된 백업 수
- 💿 **AMI 이미지** - 사용자 소유 AMI 백업 수
- ⚠️ **백업 없는 EBS** - 30일간 백업이 없는 볼륨
- 🚫 **백업 없는 RDS** - 자동 백업이 비활성화된 RDS

#### 📈 백업 분석 차트
- 📈 **백업 생성 추이** - 최근 30일간 스냅샷 생성 패턴
- 🗄️ **RDS 백업 보존 기간 분포** - 백업 정책 준수 현황

#### 📋 인프라 관리 테이블
- 🚨 **보안 위험 요소** (즉시 조치 필요한 리소스)
- 🏷️ **태그 정책 준수 현황** (최근 50개 리소스)
- ⚠️ **백업 위험 요소 및 권장사항** (백업 정책 위반 리소스)

### 💾 AWS 백업 모니터링 전용 대시보드
**백업 정책 관리를 위한 상세 백업 현황 대시보드**

#### 📊 백업 현황 요약 (6개 통계)
- 📀 **총 EBS 스냅샷** - 완료된 스냅샷 수
- 🔄 **RDS 자동 백업 설정** - 백업이 활성화된 RDS 수
- 📅 **오늘 생성된 백업** - 당일 새로 생성된 백업
- 💾 **총 백업 크기** - 전체 백업 스토리지 사용량
- 🗑️ **90일+ 오래된 백업** - 비용 최적화 대상 (경고)
- 💿 **사용자 AMI** - 인스턴스 이미지 백업

#### 📈 백업 트렌드 분석
- 📅 **일별 백업 생성 추이** (30일) - 백업 패턴 분석

#### 🔍 백업 상태별 분석
- 📊 **EBS 스냅샷 상태별 분포** (완료/대기/오류)
- 🗄️ **RDS 백업 보존 기간 분포** (정책 준수 현황)

#### 📋 백업 상세 테이블
- 📀 **최신 EBS 스냅샷 목록** (최근 50개, 상태별 색상 구분)
- 🗄️ **RDS 백업 설정 상세 현황** (백업 윈도우, 보존 기간)

### 🖥️ AWS EC2 종합 모니터링 (v12.3.3 최적화)
#### 📈 상단 통계 패널 (6개)
- 총 인스턴스 수 / 🟢 실행중 / 🔴 중지됨
- 🌐 퍼블릭 IP / 📍 AZ 개수 / 💻 타입 종류

#### 📊 분포 차트 (3개)
- **상태별 분포**: Running/Stopped 비교 (바차트)
- **타입별 분포**: t3.small, t3.medium 등 (바차트)
- **가용성 영역별 분포**: AZ간 인스턴스 분산 (바차트)

#### 📋 상세 테이블
- 필터링 가능한 인스턴스 목록
- 상태별 색상 구분 (🟢🔴🟡)
- Instance ID, Type, State, AZ, IP 주소, Launch Time

### 사용 가능한 쿼리 예시
```sql
-- 인스턴스 상태별 그룹화
SELECT instance_state as metric, COUNT(*) as value
FROM aws_ec2_instance
GROUP BY instance_state;

-- 인스턴스 타입별 분포
SELECT instance_type, COUNT(*) as count
FROM aws_ec2_instance
GROUP BY instance_type
ORDER BY count DESC;
```

## 🌐 AWS 다중 계정 모니터링 설정

### Profile 기반 다중 계정 설정

여러 AWS 계정을 동시에 모니터링하려면 AWS CLI Profile과 Steampipe Connection을 연결하여 설정할 수 있습니다.

#### 1단계: AWS CLI Profile 설정
```bash
# 각 계정별 Profile 생성
aws configure --profile production
aws configure --profile development
aws configure --profile staging

# Profile 목록 확인
aws configure list-profiles
```

#### 2단계: Steampipe Connection 설정
`~/.steampipe/config/aws.spc` 파일에 Profile별 Connection 추가:

```hcl
# 기본 connection은 그대로 유지
connection "aws" {
  plugin = "aws"
  # 기존 설정...
}

# Production 계정
connection "aws_production" {
  plugin = "aws"
  profile = "production"
  regions = ["ap-northeast-2", "us-east-1", "eu-west-1"]
}

# Development 계정
connection "aws_development" {
  plugin = "aws"
  profile = "development"
  regions = ["ap-northeast-2", "us-east-1"]
}

# Staging 계정
connection "aws_staging" {
  plugin = "aws"
  profile = "staging"
  regions = ["ap-northeast-2"]
}

# 모든 계정 통합 조회 (선택사항)
connection "aws_all_profiles" {
  plugin      = "aws"
  type        = "aggregator"
  connections = ["aws_production", "aws_development", "aws_staging"]
}
```

#### 3단계: 서비스 재시작 및 테스트
```bash
# Steampipe 재시작
steampipe service restart

# 각 계정별 연결 테스트
steampipe query "SELECT count(*) FROM aws_production.aws_ec2_instance"
steampipe query "SELECT count(*) FROM aws_development.aws_ec2_instance"
steampipe query "SELECT count(*) FROM aws_staging.aws_ec2_instance"
```

#### 4단계: 계정별 대시보드 생성
각 AWS Profile별로 독립된 대시보드를 생성하여 계정별 리소스를 분리 모니터링:

**Production 계정 전용 쿼리:**
```sql
SELECT instance_id, instance_type, instance_state
FROM aws_production.aws_ec2_instance
```

**Development 계정 전용 쿼리:**
```sql
SELECT instance_id, instance_type, instance_state
FROM aws_development.aws_ec2_instance
```

**계정 간 리소스 비교:**
```sql
SELECT 'Production' as account, count(*) FROM aws_production.aws_ec2_instance
UNION ALL
SELECT 'Development' as account, count(*) FROM aws_development.aws_ec2_instance
UNION ALL
SELECT 'Staging' as account, count(*) FROM aws_staging.aws_ec2_instance
```

### 자동화 스크립트 지원

```bash
# 다중 계정 설정 자동화
./multi-account-setup.sh

# 다중 계정 전용 대시보드 (선택사항)
# dashboards/grafana-multi-account-dashboard.json
```

### 다중 계정 모니터링 장점

✅ **계정별 독립 모니터링** - 각 AWS 계정의 리소스를 분리하여 관리
✅ **통합 비교 분석** - 여러 계정의 리소스를 한 번에 비교
✅ **환경별 관리** - Production/Development/Staging 환경 분리
✅ **보안 강화** - 계정별 접근 권한 분리 및 감사
✅ **비용 추적** - 계정별 리소스 사용량 및 비용 모니터링

## 🔧 문제 해결

### 일반적인 문제들

**AWS 연결 오류**
```bash
# AWS 자격 증명 확인
aws sts get-caller-identity

# Steampipe 서비스 재시작
steampipe service restart
```

**Grafana 접속 불가**
```bash
# Grafana 서비스 상태 확인
sudo systemctl status grafana-server

# 서비스 재시작
sudo systemctl restart grafana-server
```

**완전 재설치**
```bash
# 제거 후 재설치
./uninstall.sh      # 컴포넌트 제거 (스크립트는 보존)
./install-steampipe-grafana.sh  # 재설치
```

## 📁 파일 구조

```
steampipe/
├── install-steampipe-grafana.sh    # 메인 설치 스크립트
├── grafana-auto-provision.sh       # 전체 대시보드 자동 프로비저닝
├── verify-installation.sh          # 12개 항목 검증
├── uninstall.sh                     # 스마트 제거 스크립트
├── multi-account-setup.sh          # 🌐 다중 계정 자동 설정 스크립트
├── .env.example                     # 환경 변수 템플릿
├── grafana-datasource.yaml         # 데이터소스 설정
├── aws-profile-connections.spc     # Profile 기반 Connection 설정 예시
├── dashboards/                     # 대시보드 디렉토리
│   ├── grafana-aws-infra-comprehensive.json # 🏢 통합 인프라 대시보드 (메인)
│   ├── grafana-multi-account-dashboard.json # 🌐 다중 계정 모니터링 대시보드
│   ├── grafana-ec2-v12-optimized.json     # 🖥️ EC2 전용 대시보드
│   ├── grafana-backup-monitoring-dashboard.json # 💾 백업 모니터링 전용
│   ├── grafana-s3-security-dashboard.json # 🪣 S3 보안 대시보드
│   ├── grafana-iam-security-dashboard.json # 👤 IAM 보안 대시보드
│   ├── grafana-network-security-dashboard.json # 🌐 네트워크 보안
│   ├── grafana-security-timeline-dashboard.json # 📅 보안 타임라인
│   ├── grafana-encryption-compliance-dashboard.json # 🔐 암호화 컴플라이언스
│   ├── grafana-risk-assessment-dashboard.json # ⚠️ 위험 평가
│   ├── grafana-security-incident-dashboard.json # 🚨 보안 인시던트
│   └── grafana-security-kpi-dashboard.json # 📊 보안 KPI
├── README.md                        # 사용자 가이드
└── claude.md                        # 프로젝트 문서
```

## 🔒 보안 고려사항

### 네트워크 보안
- 기본적으로 localhost에서만 접근 가능
- 외부 접근이 필요한 경우 방화벽 설정 필요

### 필요한 최소 IAM 권한
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "iam:Get*",
                "iam:List*",
                "rds:Describe*",
                "s3:Get*",
                "s3:List*",
                "lambda:List*",
                "lambda:Get*",
                "backup:List*",
                "backup:Describe*"
            ],
            "Resource": "*"
        }
    ]
}
```

## 🎉 프로젝트 특징

### 🏢 **엔터프라이즈 설계**
- AWS 인프라 전체 현황 한 눈에 파악
- 보안 위험 요소 실시간 모니터링
- 비용 최적화 기회 자동 발견
- 컴플라이언스 준수 현황 추적
- **💾 백업 정책 준수 모니터링** (신규 추가)
- **🔄 재해복구 준비 상태 추적** (신규 추가)
- **🌐 AWS Profile 기반 다중 계정 모니터링** (신규 추가)
- **📊 계정별 독립 대시보드 및 통합 비교** (신규 추가)

### 🚀 **완전 자동화**
- **12개 대시보드 자동 프로비저닝** (다중 계정 대시보드 추가)
- 데이터소스까지 자동 설정
- AWS Profile 기반 다중 계정 자동 설정
- 사용자는 브라우저만 열면 됨

### 🛡️ **안전한 설계**
- uninstall 후에도 재설치 가능
- 스크립트 파일 보존

### 🔧 **사용자 친화적**
- 명확한 에러 메시지
- 상세한 문제 해결 가이드

## 💼 인프라 운영 활용 가이드

### 일일 모니터링 체크리스트 ✅
- [ ] 중지된 인스턴스 확인 (비용 절감)
- [ ] 보안 위험 요소 0개 유지
- [ ] 미태그 리소스 정리
- [ ] 리전별 리소스 분산 확인
- [ ] **백업 없는 중요 리소스 0개 유지** 📀
- [ ] **최근 7일 백업 생성 현황 확인** 📅
- [ ] **계정별 리소스 현황 확인** 🌐
- [ ] **계정 간 보안 정책 일관성 확인** 🔐

### 주간 백업 점검 🔄
- [ ] **RDS 자동 백업** 비활성화된 인스턴스 없음
- [ ] **30일 이상 백업 없는 EBS 볼륨** 없음
- [ ] **백업 생성 추이** 정상 패턴 확인
- [ ] **오래된 스냅샷** 정리 (비용 최적화)
- [ ] **계정별 백업 정책** 일관성 확인 🌐
- [ ] **Cross-Account 백업** 설정 점검 📋

### 월간 검토 포인트 📅
- [ ] 인스턴스 타입 최적화 기회
- [ ] 암호화 정책 준수율
- [ ] 태그 정책 준수율
- [ ] 보안 그룹 정리
- [ ] **백업 보존 정책** 검토 및 최적화
- [ ] **복구 시나리오** 테스트 실행
- [ ] **계정 간 리소스 분산** 최적화 검토 🌐
- [ ] **다중 계정 거버넌스** 정책 점검 📋
- [ ] **Cross-Account 접근 권한** 감사 🔐

### 백업 위험 등급별 대응 📊
- 🔴 **HIGH**: 즉시 조치 (RDS 백업 없음, SSH 전체 오픈 등)
- 🟡 **MEDIUM**: 7일 내 조치 (EBS 백업 없음, 미암호화 볼륨 등)
- 🟢 **LOW**: 월간 검토 (태그 정책 위반 등)

---

💡 **팁**: 더 많은 AWS 서비스를 모니터링하려면 `steampipe query ".tables aws_*"` 명령으로 사용 가능한 모든 테이블을 확인해보세요!