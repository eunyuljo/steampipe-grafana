# JSON 임포트 후 "No Data" 문제 해결 가이드

## 🔧 자동화된 해결 방법들

### 방법 1: 자동 프로비저닝 스크립트 (권장)
```bash
# 실행 권한 부여
chmod +x grafana-auto-provision.sh

# 스크립트 실행
./grafana-auto-provision.sh
```

### 방법 2: 수동 데이터소스 연결 (빠른 해결)

1. **JSON 임포트 후 각 패널에서 수행:**
   - 패널 제목 클릭 → "Edit" 선택
   - Query 탭에서 Data source를 "Steampipe"로 변경
   - "Apply" 클릭

2. **일괄 수정이 필요한 경우:**
   - Dashboard settings (⚙️) → "JSON Model" 클릭
   - `"uid": "steampipe"`를 실제 데이터소스 UID로 변경

### 방법 3: Grafana Provisioning 디렉토리 사용

```bash
# Grafana provisioning 설정
sudo mkdir -p /etc/grafana/provisioning/{datasources,dashboards}

# 데이터소스 설정 복사
sudo cp grafana-datasource.yaml /etc/grafana/provisioning/datasources/

# 대시보드 디렉토리 설정
sudo cp grafana-dashboard-*.json /etc/grafana/provisioning/dashboards/

# Grafana 재시작
sudo systemctl restart grafana-server
```

### 방법 4: API를 통한 자동 설정

```bash
# 데이터소스 UID 확인
DATASOURCE_UID=$(curl -s -u admin:admin http://localhost:3000/api/datasources | jq -r '.[] | select(.name=="Steampipe") | .uid')

# JSON 파일에서 UID 치환
sed -i "s/\"uid\": \"steampipe\"/\"uid\": \"$DATASOURCE_UID\"/g" grafana-dashboard-working.json

# 대시보드 재임포트
curl -X POST -H "Content-Type: application/json" -u admin:admin \
  -d @grafana-dashboard-working.json \
  http://localhost:3000/api/dashboards/db
```

## 🎯 가장 빠른 해결책

**즉시 해결하려면:**

1. **Grafana에서 데이터소스 이름 확인:**
   - Settings → Data Sources에서 Steampipe 데이터소스 이름 확인

2. **JSON 파일 수정:**
   ```bash
   # 실제 데이터소스 이름으로 변경
   sed -i 's/"uid": "steampipe"/"uid": "실제_데이터소스_이름"/g' *.json
   ```

3. **대시보드 재임포트:**
   - 기존 대시보드 삭제
   - 수정된 JSON 파일로 다시 임포트

## 🔍 문제 진단

**"No Data" 원인:**
1. 데이터소스 UID 불일치
2. 데이터소스 연결 실패
3. 쿼리 문법 오류
4. 권한 문제

**확인 방법:**
```bash
# Steampipe 서비스 상태 확인
steampipe service status

# 쿼리 직접 테스트
steampipe query "SELECT COUNT(*) FROM aws_ec2_instance"

# Grafana 로그 확인
sudo journalctl -u grafana-server -f
```

## ✅ 검증 방법

대시보드가 정상 작동하는지 확인:
1. 패널이 데이터를 표시하는가?
2. 쿼리가 에러 없이 실행되는가?
3. 새로고침 시 데이터가 업데이트되는가?

---

💡 **팁**: 첫 번째 패널이 작동하면 나머지는 같은 방식으로 빠르게 수정할 수 있습니다!