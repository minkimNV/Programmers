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

## 🟠 문제 10. 일일 총 판매량이 3일 연속 증가한 날짜 구하기

**설명:**
날짜별 전체 총 배송량(`SUM` of 모든 상품군)이 **3일 연속으로 증가한 경우의 마지막 날짜**를 출력하세요.

**핵심 개념:**

* `SUM(...) OVER (PARTITION BY DATE)` 또는 `GROUP BY DATE`
* `LAG()` 함수로 이전 1, 2일치와 비교
* 증가 여부 체크 후 패턴 감지

---

## 🔵 문제 11. 지역별로 월별 평균 배송량과 편차(Standard Deviation)를 구하세요.

**설명:**

* 월 단위로 묶어 `AVG()`와 `STDDEV()`를 구하세요.
* `strftime('%Y-%m', date)` 또는 `substr(date, 1, 7)`으로 월 추출

**핵심 개념:**

* 월별 분석, 파생 컬럼
* `GROUP BY REGION, MONTH` 구조

---

## 🟣 문제 12. 특정 상품군의 월별 이동 평균 구하기 (예: food)

**설명:**
각 지역에서 `food_units`의 월별 평균과 \*\*이동 평균 (최근 3개월)\*\*을 함께 출력하세요.

**핵심 개념:**

* `AVG(food_units) OVER (PARTITION BY REGION ORDER BY MONTH ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)`
* 분석용 시계열 패턴 문제

---

## 🔶 문제 13. 전체 배송량 기준 상위 25% 지역 구하기 (쿼타일)

**설명:**
모든 지역의 총 배송량 합계를 기준으로, 상위 25%에 해당하는 지역들을 구하세요.

**핵심 개념:**

* `NTILE(4) OVER (ORDER BY TOTAL DESC)` 활용
* 사분위수 분석 / 상위 분류 패턴

---

## 🔸 문제 14. 매일 가장 많이 팔린 상품군은 무엇인가요?

**설명:**
각 날짜마다 **가장 많이 팔린 상품군** 이름과 그 수량을 구하세요.

**핵심 개념:**

* 날짜 기준으로 `UNION ALL` + `ROW_NUMBER()` OVER (PARTITION BY DATE)
* 비교 기반 집계

---

## 🧩 문제 15. 누적 판매량이 1000단위 돌파한 날짜 구하기 (상품군별 또는 전체 기준)

**설명:**
상품군별로 누적 판매량을 계산하고, **1000단위 돌파 시점의 날짜**를 구하세요.
예: `clothes_units`가 누적 1000 이상이 된 첫 번째 날짜

**핵심 개념:**

* `SUM(...) OVER (PARTITION BY REGION ORDER BY DATE)` 누적합
* `WHERE 누적합 >= 1000` + `ROW_NUMBER() = 1`

---
