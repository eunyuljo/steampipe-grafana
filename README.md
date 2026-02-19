# Steampipe + Grafana AWS 모니터링 시스템

AWS 리소스를 실시간으로 모니터링할 수 있는 Steampipe와 Grafana 통합 환경을 **완전 자동화**로 구축할 수 있는 도구입니다.

## 🚀 빠른 시작

### 원클릭 설치
```bash
# 자동 설치 실행
./install-steampipe-grafana.sh

# 설치 검증
./verify-installation.sh

# 대시보드 기본 설치

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

### AWS EC2 종합 모니터링 (v12.3.3 최적화)
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
├── verify-installation.sh          # 12개 항목 검증
├── uninstall.sh                     # 스마트 제거 스크립트
├── .env.example                     # 환경 변수 템플릿
├── grafana-datasource.yaml         # 데이터소스 설정
├── dashboards/                     # 대시보드 디렉토리
│   ├── grafana-ec2-v12-optimized.json     # EC2 대시보드 (v12.3.3 최적화)
│   └── grafana-s3-security-dashboard.json  # S3 보안 대시보드
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
                "iam:List*"
            ],
            "Resource": "*"
        }
    ]
}
```

## 🎉 프로젝트 특징

### 🚀 **완전 자동화**
- 데이터소스까지 자동 설정
- 사용자는 브라우저만 열면 됨

### 🛡️ **안전한 설계**
- uninstall 후에도 재설치 가능
- 스크립트 파일 보존

### 🔧 **사용자 친화적**
- 명확한 에러 메시지
- 상세한 문제 해결 가이드

---

💡 **팁**: 더 많은 AWS 서비스를 모니터링하려면 `steampipe query ".tables aws_*"` 명령으로 사용 가능한 모든 테이블을 확인해보세요!