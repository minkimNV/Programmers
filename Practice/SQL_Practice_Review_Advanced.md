# 중-고급
지금까지 다룬 문제들은 초-중급 수준의 **단일 테이블 기반 집계**가 중심이었는데,  
이제는 **패턴 분석**, **비교**, **파생 지표 생성**, **윈도우 함수 심화** 등을 통해 **중급-고급 수준 문제로 확장**하여 응용했습니다.  

---

## 🔴 문제 9. 각 지역에서 가장 많이 팔린 상품군은 무엇인가요?  

**설명:**
`CLEANED` 데이터셋은 날짜, 지역, 그리고 다섯 가지 상품군의 배송 수량을 포함하고 있습니다.  
이 문제에서는 지역(region)별로 다섯 가지 상품군(beverages, food, electronics, clothes, tools) 중 가장 많이 배송된 상품군 하나를 찾아야 합니다.  
지역은 편의상 코드로 대체합니다. 모든 지역(SIN51, DUB53, IAD77, PDX79)은 총 4곳입니다.  

각 지역에서 **가장 많이 팔린 하나의 상품군(category) 이름과 판매량(total_units)**을 출력하는 것이 목표입니다.  

이를 위해 아래의 것들을 생각했습니다.:  

1. 원본 데이터셋에서는 상품군이 각각의 열로 나뉘어 있는 형태이므로, UNPIVOT하여 상품군을 컬럼의 값으로 넣어줄 겁니다.
2. 각 지역별로 상품군 총 합을 계산합니다.
3. 가장 많이 팔린 상품군을 하나만 남기기 위해 ROW_NUMBER()를 사용할 겁니다.  
이 방식은 각 지역(region)을 기준으로 정렬된 순위 중 1등(rn = 1)만 선택하는 방식입니다.

### 답변:  

```sql
WITH CLEANED AS (
	SELECT
	*,
	MAX(CLEANED_DATE) OVER (ORDER BY ROW_ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS FILLED_DATE
	FROM (
		SELECT
		*,
		NULLIF(DATE, '-') AS CLEANED_DATE,
		row_number() OVER () AS ROW_ID
		FROM data4
		)
)

, UNPIVOTING AS (
	SELECT REGION, 'beverages' AS CATEGORY, SUM(beverages_units) AS TOTAL_UNITS 
	FROM CLEANED
	GROUP BY REGION
	
	UNION ALL
	
	SELECT REGION, 'food', SUM(food_units)
	FROM CLEANED
	GROUP BY REGION
	
	UNION ALL
	
	SELECT REGION, 'electronics', SUM(electronics_units)
	FROM CLEANED
	GROUP BY REGION
	
	UNION ALL
	
	SELECT REGION, 'clothes', SUM(clothes_units) 
	FROM CLEANED
	GROUP BY REGION
	
	UNION ALL
	
	SELECT REGION, 'tools', SUM(tools_units) 
	FROM CLEANED
	GROUP BY REGION
)

, MOST_SELL AS (
	SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY REGION ORDER BY TOTAL_UNITS DESC) AS RN
	FROM UNPIVOTING
)

SELECT
REGION,
CATEGORY,
TOTAL_UNITS
FROM MOST_SELL
WHERE RN = 1
```

### 풀이  

1. **UNPIVOT 단계 (`UNION ALL`)**
   * 다섯 개 상품군 각각에 대해 `region`, `category`, `SUM(...)` 값을 추출하고
   * `UNION ALL`로 붙여서 열(column)을 행(row)으로 전환합니다.  


2. **RANKING 단계 (`ROW_NUMBER()`)**  

   * UNPIVOT 결과를 기반으로, 각 `region` 내에서 `total_units` 기준 내림차순 정렬을 수행하고
   * `ROW_NUMBER()`를 통해 순위를 부여합니다.  

3. **최종 선택 단계 (`WHERE rn = 1`)**  

   * 가장 많이 팔린 상품군만 남기기 위해 순위가 1위인 것만 필터링합니다.  

행을 변환하고, 순위를 지정해서 다중 열을 하나의 값으로 비교하는 방식으로 풀었습니다. 

**풀이 요약:**  

* `UNION ALL`로 열 → 행 전환 (UNPIVOT)
* `SUM()`으로 상품군별 판매량 집계
* `ROW_NUMBER()`로 지역 내 최다 상품군 추출
* `WHERE rn = 1`로 1등만 필터링

**이 외 확장 쿼리 (상위 2개 상품군까지 출력):**  

```sql
SELECT region, category, total_units
FROM RANKED
WHERE rn <= 2
ORDER BY region, rn
```  

**설명:**  

지역별로 상위 두 개 상품군을 보고 싶을 경우 `rn <= 2` 조건으로 필터링하면 됩니다.

---

## 🟠 문제 10. 일일 총 배송량이 3일 연속 증가한 마지막 날짜를 구하세요

### 문제를 푸는 방법

1. 먼저 **날짜별로 총 배송량**을 구합니다.  
   이 때는 다섯 개 상품군의 배송 수량을 `SUM()`해서 `total_units`로 만듭니다.  
2. 윈도우 함수 `LAG()`를 활용해 **이전 날짜들의 배송량**을 각각 가져옵니다.  
   즉, `LAG(total_units, 1)`, `LAG(..., 2)`, `LAG(..., 3)` 을 써서 현재 날짜 기준 1\~3일 전 값을 가져옵니다.  
3. 그 다음 `CASE WHEN`으로 세 날짜가 모두 이전보다 큰 경우만 필터링합니다.  
4. 그 결과에서 `ORDER BY DATE DESC LIMIT 1`로 마지막 날짜를 선택합니다.  

---

### 답변:

```sql
WITH CLEANED AS (
	SELECT
	*,
	MAX(CLEANED_DATE) OVER (ORDER BY ROW_ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS FILLED_DATE
	FROM (
		SELECT
		*,
		NULLIF(DATE, '-') AS CLEANED_DATE,
		ROW_NUMBER() OVER () AS ROW_ID
		FROM data4
		)
)

, TOTAL_SUM AS (
	SELECT
	FILLED_DATE AS DATE,
	SUM(beverages_units+food_units+electronics_units+clothes_units+tools_units) AS TOTAL
	FROM CLEANED
	GROUP BY FILLED_DATE
)

, LAGGED AS (
	SELECT
	DATE,
	TOTAL,
	LAG(TOTAL, 3) OVER (ORDER BY DATE) AS THREE,
	LAG(TOTAL, 2) OVER (ORDER BY DATE) AS TWO,
	LAG(TOTAL, 1) OVER (ORDER BY DATE) AS ONE
	FROM TOTAL_SUM
)

SELECT * FROM LAGGED
WHERE THREE < TWO AND TWO < ONE AND ONE < TOTAL
ORDER BY DATE DESC
LIMIT 1
```

### 풀이  

1. **`CLEANED` CTE**:
   누락된 날짜를 이전 행의 날짜 값으로 채웁니다.
   원래의 순서를 유지하기 위해 ROW_NUMBER()를 사용했습니다.
2. **`TOTAL_SUM` CTE**:
   `CLEANED` 테이블에서 추출한 날짜(FILLED_DATE)별로 다섯 상품군의 총 배송량을 계산합니다.
3. **`LAGGED` CTE**:
   현재 날짜를 기준으로 이전 1일, 2일, 3일의 배송량을 `LAG()` 함수를 통해 가져옵니다.
   이렇게 하면 각 날짜에서 3일 연속 증가했는지를 비교할 수 있게 됩니다
4. **최종 선택**:
   3일 연속 증가 조건 (`3일 전 < 2일 전 < 1일 전 < 현재`)을 만족하는 행만 필터링하여, 조건을 만족하는 날짜 중 가장 마지막 날짜(`ORDER BY FILLED_DATE DESC LIMIT 1`)만 출력합니다.

---

**풀이 요약:**

* 날짜별 총 배송량 집계 (`GROUP BY + SUM`)
* `LAG()`로 3일 전까지의 값 추적
* 세 값 연속 증가 조건 필터링
* 가장 마지막 날짜만 `LIMIT 1`

---

**이 외 가능한 확장 쿼리 (모든 연속 증가 날짜 출력):**

```sql
SELECT * FROM LAGGED
WHERE THREE < TWO AND TWO < ONE AND ONE < TOTAL
ORDER BY DATE
```

**설명:**
조건을 만족하는 날짜들을 모두 출력하면, **연속 상승 시점 전체를 분석할 수 있습니다.**

---

## 🔶 문제 11. 전체 배송량 기준 상위 25% 지역 구하기 (쿼타일)

### 문제를 푸는 방법

1. `GROUP BY REGION`을 사용해 각 지역별로 전체 배송량을 합산합니다.
   다섯 개 상품군을 모두 더해 `total_units`로 계산합니다.
2. 윈도우 함수 `NTILE(4) OVER (ORDER BY total_units DESC)`를 사용해
   **배송량 기준 상위 → 하위 순으로 4개의 그룹(사분위수)** 로 나눕니다.
3. `tile = 1`인 지역들만 필터링하면, \*\*상위 25%\*\*에 해당하는 지역만 남습니다.

> 📌 `NTILE(4)`은 레코드 수를 균등하게 4등분하므로, 정렬 순서를 기준으로 각 그룹을 나눌 수 있습니다.

---

### 답변:

```sql
WITH CLEANED AS (
	SELECT
	*,
	MAX(CLEANED_DATE) OVER (ORDER BY ROW_ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS FILLED_DATE
	FROM (
		SELECT
		*,
		NULLIF(DATE, '-') AS CLEANED_DATE,
		row_number() OVER () AS ROW_ID
		FROM data4
		)
)

, REGION_TOTAL AS (
	SELECT
	REGION,
	SUM(beverages_units + food_units + electronics_units + clothes_units + tools_units) AS TOTAL_UNITS
	FROM CLEANED
	GROUP BY REGION
)

, RANKED AS (
	SELECT
	*,
	NTILE(4) OVER (ORDER BY TOTAL_UNITS DESC) AS TILE
	FROM REGION_TOTAL
)

SELECT
REGION,
TOTAL_UNITS
FROM RANKED
WHERE TILE = 1
```

### 풀이

1. **REGION_TOTALS**:
   각 지역별로 배송량을 합산하여 `TOTAL_UNITS`를 구합니다.
   이는 다섯 상품군을 모두 더한 값입니다.
2. **RANKED**:
   `NTILE(4)` 윈도우 함수를 사용해 총합이 높은 순서(`ORDER BY TOTAL_UNITS DESC`)로 사분위 구간을 나눕니다.
   여기서 `TILE = 1`인 그룹이 **상위 25%에 해당하는 지역**입니다.
3. **최종 출력**:
   상위 25% 지역들의 이름과 총 배송량을 내림차순 정렬로 출력합니다.

**풀이 요약:**

* `GROUP BY REGION`으로 지역별 총합 계산
* `NTILE(4)`로 사분위수 구간 나누기
* `TILE = 1`로 상위 25% 지역 필터링

**이 외 가능한 확장 쿼리 (모든 사분위별 그룹 보기):**

```sql
SELECT REGION, TOTAL_UNITS, TILE
FROM RANKED
ORDER BY TILE, TOTAL_UNITS DESC
```

**설명:**
모든 지역을 사분위 그룹별로 정렬해서 보고 싶을 경우 유용합니다.
보고서나 분석 자료 작성 시 각 구간별 특성 파악에 자주 쓰입니다.

---

## 🔸 문제 12. 매일 가장 많이 팔린 상품군은 무엇인가요?

**설명:**
각 날짜마다 **가장 많이 팔린 상품군** 이름과 그 수량을 구하세요.

**핵심 개념:**

* 날짜 기준으로 `UNION ALL` + `ROW_NUMBER()` OVER (PARTITION BY DATE)
* 비교 기반 집계

---

## 🧩 문제 13. 누적 판매량이 1000단위 돌파한 날짜 구하기 (상품군별 또는 전체 기준)

**설명:**
상품군별로 누적 판매량을 계산하고, **1000단위 돌파 시점의 날짜**를 구하세요.
예: `clothes_units`가 누적 1000 이상이 된 첫 번째 날짜

**핵심 개념:**

* `SUM(...) OVER (PARTITION BY REGION ORDER BY DATE)` 누적합
* `WHERE 누적합 >= 1000` + `ROW_NUMBER() = 1`

---
