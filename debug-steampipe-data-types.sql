-- Steampipe 데이터 타입 진단 쿼리들

-- 1. 기본 쿼리와 데이터 타입 확인
SELECT
  instance_state,
  COUNT(*) as count,
  pg_typeof(instance_state) as state_type,
  pg_typeof(COUNT(*)) as count_type
FROM aws_ec2_instance
GROUP BY instance_state;

-- 2. 숫자 타입 강제 변환 테스트
SELECT
  instance_state::text as state,
  COUNT(*)::int as count,
  pg_typeof(instance_state::text) as state_type,
  pg_typeof(COUNT(*)::int) as count_type
FROM aws_ec2_instance
GROUP BY instance_state;

-- 3. Grafana pie chart가 선호하는 컬럼명 사용
SELECT
  instance_state as name,
  COUNT(*) as value,
  pg_typeof(instance_state) as name_type,
  pg_typeof(COUNT(*)) as value_type
FROM aws_ec2_instance
GROUP BY instance_state;

-- 4. JSON 형태로 결과 확인 (Steampipe 특성)
SELECT
  jsonb_build_object(
    'category', instance_state,
    'value', COUNT(*)
  ) as pie_data
FROM aws_ec2_instance
GROUP BY instance_state;

-- 5. 실제 행 개수와 결과 집합 구조 확인
SELECT
  'row_' || row_number() OVER() as row_id,
  instance_state,
  COUNT(*) as count
FROM aws_ec2_instance
GROUP BY instance_state;

-- 6. 비교용: 단순한 테이블 생성 후 같은 쿼리
CREATE TEMPORARY TABLE temp_instances AS
SELECT 'running' as state, 1 as id
UNION ALL SELECT 'running', 2
UNION ALL SELECT 'stopped', 3;

SELECT
  state,
  COUNT(*) as count,
  pg_typeof(state) as state_type,
  pg_typeof(COUNT(*)) as count_type
FROM temp_instances
GROUP BY state;