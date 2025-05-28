# SUBWAY_DISTANCE 테이블
# 노선별로
# 노선, 총 누계 거리, 평균 역 사이 거리 조회

# 총 누계거리는 테이블 내 존재하는 역들의 역 사이 거리의 총 합을 뜻합니다.
# 총 누계 거리 TOTAL_DISTANCE 소수 둘째자리 단위(km)
# 평균 역 사이 거리 AVERAGE_DISTANCE 소수 셋째 자리 단위(km)
# 총 누계 거리를 기준으로 내림차순


SELECT
ROUTE,
CONCAT(ROUND(SUM(D_BETWEEN_DIST), 1), 'km') AS TOTAL_DISTANCE,
CONCAT(ROUND(AVG(D_BETWEEN_DIST), 2), 'km') AS AVERAGE_DISTANCE
FROM SUBWAY_DISTANCE
GROUP BY ROUTE
ORDER BY ROUND(SUM(D_BETWEEN_DIST), 1) DESC