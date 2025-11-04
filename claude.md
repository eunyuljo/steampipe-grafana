# Steampipe + Grafana 자동화 구축 프로젝트

> Claude Code와 함께한 AWS 모니터링 시스템 구축 전 과정 기록

## 🎯 프로젝트 개요

**목표**: AWS 리소스를 실시간으로 모니터링할 수 있는 Steampipe + Grafana 통합 환경을 **완전 자동화**로 구축

**핵심 요구사항**:
- Python 3.10+ (pyenv 권장) 환경
- 원클릭 설치 및 완전 자동화
- Docker 복잡성 제거, 로컬 설치 우선
- 데이터소스 자동 설정
- 사용자 친화적 스크립트

## 📋 프로젝트 진행 과정

### 1단계: 초기 테스트 및 문제 발견 (2025-11-04 06:00-07:00)

#### 성공한 부분
- ✅ Python 스크립트로 AWS EC2 데이터 수집 (4개 인스턴스)
- ✅ Steampipe 로컬 설치 및 AWS 플러그인 연동
- ✅ SQL 쿼리로 EC2 상태별 분포 확인

#### 발견된 문제
- ❌ Docker Compose 접근법의 한계
- ❌ Google Artifact Registry 인증 오류
- ❌ 컨테이너 간 네트워킹 복잡성

### 2단계: Docker vs 로컬 설치 결정 (2025-11-04 07:00-08:00)

#### Docker Compose 시도 및 실패
```bash
# 시도한 Docker 설정
- turbot/steampipe 공식 이미지
- 대체 이미지들
- 커스텀 Dockerfile
```

**실패 원인**:
- `response status code 403: denied: Unauthenticated request`
- Google Artifact Registry 인증 문제
- 플러그인 다운로드 차단

#### 로컬 설치 선택
**이유**:
- 더 간단하고 직접적
- 네트워킹 복잡성 제거
- 더 나은 성능과 안정성

### 3단계: 환경 정리 및 처음부터 재구축 (2025-11-04 08:00-08:30)

#### 완전 환경 초기화
```bash
# 모든 컴포넌트 제거
steampipe service stop
sudo systemctl stop grafana-server
sudo dnf remove grafana -y
rm -rf ~/.steampipe ~/.cache/steampipe
```

#### 핵심 발견: 개발 브랜치 설치 스크립트
**문제 해결 키**:
```bash
sudo /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/turbot/steampipe/refs/heads/develop/scripts/install.sh)"
```

**결과**:
- ✅ Steampipe v2.3.2 설치 성공
- ✅ AWS 플러그인 v1.26.0 설치 성공
- ✅ Google Artifact Registry 인증 문제 해결

### 4단계: 완전 자동화 스크립트 개발 (2025-11-04 08:30-09:00)

#### 개발된 스크립트들

**1. `install-steampipe-grafana.sh` (메인 설치 스크립트)**
- OS 자동 감지 (Amazon Linux, Ubuntu, CentOS)
- Python 3.10+ 환경 검증
- Steampipe v2.3.2 자동 설치
- AWS 플러그인 자동 설치
- Grafana 자동 설치 및 서비스 시작
- **🆕 Grafana 데이터소스 자동 설정** (API 활용)
- 연결 테스트 및 검증

**2. `verify-installation.sh` (검증 스크립트)**
- 12개 항목 체크
- 바이너리, 서비스, 포트, HTTP, DB 연결, AWS 연결 등
- 실패 시 문제 해결 가이드 제공

**3. `uninstall.sh` (제거 스크립트)**
- 스마트 제거: 컴포넌트만 제거, 스크립트는 보존
- 재설치 가능하도록 설계
- 완전한 시스템 정리

#### 설정 파일들
- `.env.example`: 환경 변수 템플릿
- `grafana-datasource.yaml`: 데이터소스 설정
- `grafana-dashboard-ec2.json`: EC2 모니터링 대시보드

## 🔧 기술적 해결책들

### 1. Google Artifact Registry 인증 문제 해결
**문제**: `403 Denied: Unauthenticated request`
**해결**: 개발 브랜치 설치 스크립트 사용
```bash
https://raw.githubusercontent.com/turbot/steampipe/refs/heads/develop/scripts/install.sh
```

### 2. Python 환경 검증 자동화
```bash
# Python 3.10+ 버전 체크
python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
# pyenv 환경 자동 감지
```

### 3. Grafana 데이터소스 자동 설정
```bash
# API를 통한 자동 데이터소스 생성
curl -X POST -H "Content-Type: application/json" \
     -u admin:admin \
     -d "$datasource_json" \
     http://localhost:3000/api/datasources
```

### 4. 패키지 충돌 해결
```bash
# Amazon Linux curl 충돌 해결
sudo dnf install -y --allowerasing curl wget unzip
```

## 📊 최종 검증 결과

### 성능 지표
- **설치 시간**: ~5-10분 (네트워크 속도에 따라)
- **검증 항목**: 12/12 통과
- **AWS 연결**: EC2 인스턴스 4개 정상 조회
- **메모리 사용량**: Grafana ~92MB, Steampipe ~최소

### 지원 환경
- ✅ Amazon Linux 2023
- ✅ Ubuntu 20.04+
- ✅ CentOS/RHEL 8+
- ✅ Python 3.10+ (pyenv 권장)

## 🎉 최종 결과물

### 완성된 파일 구조
```
steampipe/
├── install-steampipe-grafana.sh    # 메인 설치 스크립트
├── verify-installation.sh          # 12개 항목 검증
├── uninstall.sh                     # 스마트 제거 스크립트
├── .env.example                     # 환경 변수 템플릿
├── grafana-datasource.yaml         # 데이터소스 설정
├── grafana-dashboard-ec2.json      # EC2 대시보드
├── README.md                        # 사용자 가이드
└── claude.md                        # 이 문서
```

### 사용법
```bash
# 1. 원클릭 설치
./install-steampipe-grafana.sh

# 2. 검증
./verify-installation.sh

# 3. 웹 접속
# http://localhost:3000 (admin/admin)
# 데이터소스 자동 설정됨!

# 4. 필요시 제거
./uninstall.sh
```

## 🔍 주요 학습 내용

### 1. Docker의 한계점
- **복잡성**: 네트워킹, 볼륨, 권한 문제
- **의존성**: 외부 레지스트리 인증 문제
- **오버헤드**: 불필요한 추상화 레이어
- **결론**: 단순한 모니터링 환경에는 로컬 설치가 더 적합

### 2. 자동화의 핵심 원칙
- **멱등성**: 여러 번 실행해도 안전
- **에러 핸들링**: 실패 시 명확한 가이드 제공
- **사용자 경험**: 최소한의 수동 작업
- **유지보수성**: 스크립트 파일 보존으로 재설치 가능

### 3. API 활용한 설정 자동화
- Grafana REST API를 활용한 데이터소스 자동 생성
- 연결 테스트 자동 실행
- 실패 시 fallback으로 수동 설정 정보 제공

## 🚀 향후 개선 방향

### 단기 개선안
- [ ] 더 많은 AWS 서비스 대시보드 추가
- [ ] 알림 설정 자동화
- [ ] 보안 설정 강화

### 장기 개선안
- [ ] Multi-cloud 지원 (Azure, GCP)
- [ ] Container 배포 옵션 (필요시)
- [ ] CI/CD 파이프라인 통합

## 📝 프로젝트 회고

### 성공 요인
1. **문제 중심 접근**: Docker 문제 발견 후 빠른 방향 전환
2. **사용자 관점**: 복잡성보다 실용성 우선
3. **완전 자동화**: 데이터소스 설정까지 자동화
4. **안전한 설계**: uninstall 후에도 재설치 가능

### 배운 점
1. **도구 선택의 중요성**: 항상 최신 = 최선은 아님
2. **사용자 경험 우선**: 기술적 완성도보다 사용 편의성
3. **문제 해결 과정**: 근본 원인 파악의 중요성

---

**프로젝트 완료일**: 2025-11-04
**개발 도구**: Claude Code
**총 개발 시간**: ~3시간
**최종 검증**: 12/12 항목 통과 ✅

> 이 프로젝트는 "복잡함보다 단순함이, 기술적 완성도보다 사용자 경험이 더 중요하다"는 것을 보여주는 좋은 사례입니다.