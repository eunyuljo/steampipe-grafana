# Steampipe + Grafana Docker 환경

AWS 리소스를 SQL로 조회하고 Grafana로 시각화하는 Docker Compose 기반 모니터링 환경입니다.

## 빠른 시작

```bash
# 1. AWS 자격 증명 설정 (선택사항)
cp .env.example .env
vi .env  # AWS 키 입력

# 2. 서비스 시작
docker-compose up -d

# 3. Grafana 접속
# http://localhost:3000 (admin/admin)

# 4. 대시보드 Import
# grafana-dashboard-ec2.json 파일을 Grafana에서 Import
```

## 구성 요소

- **Steampipe** (포트 9193): AWS API를 SQL로 조회
- **Grafana** (포트 3000): 데이터 시각화 대시보드
- **자동 연결**: Grafana에 Steampipe 데이터소스 자동 설정

## 파일 구조

```
.
├── docker-compose.yml                    # Docker 오케스트레이션
├── .env.example                          # AWS 자격증명 템플릿
├── grafana/
│   └── provisioning/
│       └── datasources/steampipe.yml    # Grafana 자동 설정
├── grafana-dashboard-ec2.json           # EC2 대시보드
├── queries.sql                          # 유용한 쿼리 모음
└── test.py                              # 데이터 수집 스크립트
```

## 주요 명령어

```bash
# 서비스 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f

# 서비스 중지
docker-compose down

# Steampipe 쿼리 실행
docker exec steampipe steampipe query "SELECT * FROM aws_ec2_instance LIMIT 5"
```

## 자세한 가이드

상세한 설정 및 사용 방법은 [DOCKER_SETUP.md](DOCKER_SETUP.md)를 참고하세요.

## 데이터 수집

`test.py` 스크립트로 EC2 정보를 CSV로 수집할 수 있습니다:

```bash
./test.py
# 결과는 results/latest/ 에 저장됨
```

## 쿼리 예제

`queries.sql` 파일에 다음 정보를 조회하는 15개 쿼리가 포함되어 있습니다:

1. 기본 인스턴스 정보
2. 네트워크 정보 (IP, VPC, 서브넷)
3. 보안 그룹
4. VPC별 그룹화
5. Elastic IP
6. EBS 볼륨
7. 종합 요약

자세한 내용은 파일을 직접 확인하세요.
# steampipe-grafana
