# 📊 SQL 코딩테스트 복기

이 문서는 IT 기업 SQL 코딩 테스트 이후 제공받은 데이터셋을 활용한 문제집입니다.  
문제는 실제 코딩 테스트와 동일한 부분도 있지만, 응용할 수 있는 부분은 자체적으로 정의하여 문제 풀이를 했습니다.  
모든 문제는 배송/판매 데이터를 기반으로 하며, 데이터 전처리, 집계, 조건 분석, 윈도우 함수 등을 포괄합니다.
모든 문제는 초-중급 수준의 문제입니다.


---

**실행 환경: `DB Browser for SQLite Version 3.13.1`**  

---

  
## 🟢 문제 1. 날짜 값이 없는 행에 날짜를 위에서 채워 넣으세요  

**답변:**  


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
    FROM TEST
  )
)
```

  
**풀이:**  

제공된 데이터셋에서는 `'date'` 컬럼의 값이 `'-'`으로 입력되어 있는 경우가 있습니다.  
이런 값들은 의미 있는 날짜가 아니므로, 해당 행에는 이전 유효한 날짜 값을 채워넣는 처리가 필요했습니다.  
따라서, 원래 데이터 순서를 유지한 상태로 **이전 유효한 날짜 값을 채워 넣어 새로운 열** 을 생성하고자 했습니다.  


이를 위해 세 단계를 거쳤습니다.  

1. `NULLIF(DATE, '-') AS CLEANED_DATE` : `'-'`값을 `NULL`로 변환하여 결측처리 합니다.
2. `ROW_NUMBER() OVER () AS ROW_ID` : 원래 데이터 순서를 보장하기 위해 고유 번호를 부여했습니다.
3. `MAX(CLEANED_DATE) OVER (ORDER BY ROW_ID ... ) AS FILLED_DATE` : 현재 행까지의 가장 최신의 유효 날짜를 선택합니다.
이 쿼리는 위에서 아래로 스캔하면서 "**마지막으로 나타난 NULL이 아닌 날짜**"를 채워넣는 방식입니다.  

또한, `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`를 사용해서 정확한 범위를 지정했습니다.  

**풀이 요약:**  

* `NULLIF`로 결측값 처리
* `ROW_NUMBER()`로 순서 보장
* `MAX(...) OVER` 윈도우 함수로 이전 날짜 채움
* 데이터 정제, 순서 유지, 전처리 패턴 연습

**이 외 가능한 답변:**  

```sql
WITH CLEANED AS (
  SELECT *,
         MAX(NULLIF(DATE, '-')) OVER (ORDER BY ROW_NUMBER() OVER ()) AS FILLED_DATE
  FROM TEST
)
```

**설명:**  

이 쿼리도 가능한 쿼리입니다.  
서브 쿼리 없이 윈도우 함수 안에 또 다른 윈도우 함수를 쓰는 형태로 쿼리를 간소화하려고 했습니다.  
단, SQLite 구버전에서는 작동하지 않을 수 있습니다. 대부분의 SQL 엔진에서는 이 방식도 허용됩니다.  

---

## 🔴 문제 2. 싱가포르(SIN51) 지역에서 가장 많은 배송이 이루어진 날짜는?  

싱가포르의 지역 코드는 `'SIN51'`입니다.  
**본 문제부터는 데이터 추출이 기존 데이터셋이 아닌 **문제 1번**에서 전처리된 데이터셋 `CLEANED`를 사용합니다.**  
`CLEANED`는 `date` 컬럼의 `'-'` 값을 앞의 날짜로 채워 넣은 결과입니다.  

배송 수량은 모든 상품군(beverages, food, electronics, clothes, tools)의 수량을 합한 값입니다.  

---

**답변:**  


```sql
SELECT
  FILLED_DATE AS DATE,
  REGION,
  SUM(beverages_units + food_units + electronics_units + clothes_units + tools_units) AS TOTAL_UNITS
FROM CLEANED
WHERE REGION = 'SIN51'
GROUP BY FILLED_DATE, REGION
ORDER BY TOTAL_UNITS DESC 
LIMIT 1
```

**풀이:**  

우선 싱가포르 지역의 코드 `'SIN51'`을 기준으로 데이터를 필터링합니다.  
그 후, 날짜(`FILLED_DATE`)별로 상품군별 수량을 모두 합산하여 `TOTAL_UNITS`를 계산했습니다.  
이때 `SUM()` 안에 모든 상품군의 컬럼을 더하여 총합을 구했습니다.  
마지막으로 `ORDER BY TOTAL_UNITS DESC`로 총 배송량 기준 내림차순 정렬 후,  
`LIMIT 1`을 통해 **가장 많은 배송이 이루어진 날짜 한 개**를 추출했습니다.  


**풀이 요약:**  

* `WHERE REGION = 'SIN51'`로 싱가포르 지역만 추출
* 각 날짜별 총 배송량을 계산하기 위해 `SUM(...)` 사용
* `ORDER BY TOTAL_UNITS DESC LIMIT 1`로 가장 많은 날을 선택

  
**이 외 가능한 답변 (컬럼별 합산 후 계산하는 방식):**  

```sql
SELECT
  FILLED_DATE AS DATE,
  REGION,
  SUM(beverages_units) + SUM(food_units) + SUM(electronics_units) + SUM(clothes_units) + SUM(tools_units) AS TOTAL_UNITS
FROM CLEANED
WHERE REGION = 'SIN51'
GROUP BY FILLED_DATE, REGION
ORDER BY TOTAL_UNITS DESC 
LIMIT 1
```


**풀이:**  

이 방식은 `SUM(beverages_units + ... + tools_units)` 대신, 각 컬럼을 개별적으로 `SUM()`하고 더하는 방식입니다.  
SQL 엔진에 따라 **표현의 명확성**이 더 높아질 수 있으며, 컬럼 단위별 개별 합도 필요할 경우 이 방식이 유리할 수 있습니다.  


---

## 🟠 문제 3. 모든 지역을 합쳐 보았을 때, 툴(tools) 배송량이 가장 적었던 날짜는?  


**답변:**  

```sql
SELECT
  FILLED_DATE AS DATE,
  SUM(TOOLS_UNITS) AS TOTAL_TOOLS
FROM CLEANED
GROUP BY FILLED_DATE
ORDER BY TOTAL_TOOLS
LIMIT 1
```


**풀이:**  

* `CLEANED` 데이터셋을 기준으로 모든 지역 데이터를 대상으로 집계합니다.
* 날짜별(`FILLED_DATE`)로 `tools_units` 값을 합산하여 `TOTAL_TOOLS`를 계산합니다.
* 이후 `ORDER BY TOTAL_TOOLS ASC`를 통해 툴 배송량이 **가장 적은 날짜**가 위로 오도록 정렬합니다.
* 마지막으로 `LIMIT 1`을 사용해 그 중 **가장 적은 날 한 개만 추출**합니다.

이와 같은 방식은 실무에서도 **최소 판매량**, **최소 방문 수**, **최소 트래픽** 등의 데이터를 찾을 때 자주 사용했습니다.

**풀이 요약:**  

* `GROUP BY FILLED_DATE`로 날짜별로 묶고
* `SUM(tools_units)`로 툴 배송량 합산
* `ORDER BY ASC LIMIT 1`로 최소값 추출

**이 외 가능한 확장 쿼리 (배송량이 가장 적은 상위 3개 날짜):**  

```sql
SELECT
  FILLED_DATE AS DATE,
  SUM(TOOLS_UNITS) AS TOTAL_TOOLS
FROM CLEANED
GROUP BY FILLED_DATE
ORDER BY TOTAL_TOOLS
LIMIT 3
```

**설명:**  

툴 배송량이 적었던 날짜를 한 개가 아니라 여러 개 알고 싶을 때 유용합니다. `LIMIT`의 숫자만 조정하면 쉽게 응용 가능합니다.  

---

## 🟡 문제 4. 싱가포르에서 음식을 음료보다 더 많이 배송한 날은 며칠인가요?

**답변:**

```sql
SELECT
  SUM(DAYS) AS DAYS
FROM (
  SELECT
    CASE WHEN food_units > beverages_units THEN 1
         ELSE 0
    END AS DAYS
  FROM CLEANED
  WHERE REGION = 'SIN51'
)
```

**풀이:**

* 싱가포르의 지역 코드는 `'SIN51'` 입니다. 먼저 지역이 `'SIN51'`인 행만 필터링합니다.
* 각 행에 대해 `food_units > beverages_units` 조건을 비교하고, 조건을 만족하면 `1`, 그렇지 않으면 `0`을 반환합니다.
* 이 결과를 `DAYS`라는 가상의 컬럼으로 만든 후, 그 총합을 `SUM(DAYS)`로 계산하면 조건을 만족한 행의 개수가 됩니다.
* 즉, **음식이 음료보다 더 많이 배송된 날(행)의 수**를 계산한 것입니다.

**풀이 요약:**

* `WHERE REGION = 'SIN51'`로 지역 필터
* `CASE WHEN`으로 조건 만족 여부를 0 또는 1로 변환
* `SUM(...)`을 통해 조건 만족 행 수 계산

**이 외 가능한 답변 (조건 필터 방식):**

```sql
SELECT
  COUNT(*) AS DAYS
FROM CLEANED
WHERE REGION = 'SIN51'
  AND food_units > beverages_units
```

**설명:**  

`CASE WHEN` 없이도 동일한 결과를 얻을 수 있습니다. 조건을 만족하는 행만 남기고, 전체 행 개수를 `COUNT(*)`로 계산하면 됩니다.  
SQL 표현을 단순화하고 싶을 때 좋은 방식입니다.  

---

## 🟢 문제 5. 날짜별 지역별로 상품군별 합계를 출력하세요

**답변:**  

```sql
SELECT
  FILLED_DATE AS DATE,
  REGION,
  SUM(beverages_units) AS TOTAL_B,
  SUM(food_units) AS TOTAL_F,
  SUM(electronics_units) AS TOTAL_E,
  SUM(clothes_units) AS TOTAL_C,
  SUM(tools_units) AS TOTAL_T,
  SUM(beverages_units + food_units + electronics_units + clothes_units + tools_units) AS TOTAL_UNITS
FROM CLEANED
GROUP BY FILLED_DATE, REGION
ORDER BY FILLED_DATE ASC, REGION DESC, TOTAL_UNITS DESC
````

**풀이:**  

* `CLEANED` 데이터셋에서 날짜(`FILLED_DATE`)와 지역(`REGION`)을 기준으로 `GROUP BY`를 수행합니다.
* 각 상품군에 대해 `SUM()`을 사용하여 합계를 계산하고, 이를 각각 `TOTAL_B`, `TOTAL_F`, ..., `TOTAL_T`로 출력합니다.
* 마지막 열 `TOTAL_UNITS`는 모든 상품군 수량을 더한 값입니다.
* 결과에는 날짜, 지역, 각 상품군별 합계, 전체 합계를 포함합니다.
* 📌 단, `beverages_units + ...`는 `SUM()` 없이 계산되므로, 집계 기준으로는 부정확할 수 있습니다. `SUM(beverages_units) + ...`로 바꾸는 것이 안전합니다.
* `ORDER BY`는 날짜 오름차순, 지역 내림차순, 총합 내림차순으로 정렬하여 **의미 있는 정렬 결과**를 도출합니다.

---

**풀이 요약:**  

* 날짜-지역 기준 `GROUP BY`
* 각 상품군 `SUM()` 집계
* 전체 수량은 직접 더하거나 `SUM(...) + ...`으로 처리
* 정렬 기준도 의미에 맞게 구성

---

**이 외 가능한 수정 쿼리:**  

```sql
SELECT
  FILLED_DATE AS DATE,
  REGION,
  SUM(beverages_units) AS TOTAL_B,
  SUM(food_units) AS TOTAL_F,
  SUM(electronics_units) AS TOTAL_E,
  SUM(clothes_units) AS TOTAL_C,
  SUM(tools_units) AS TOTAL_T,
  SUM(beverages_units) + SUM(food_units) + SUM(electronics_units) + SUM(clothes_units) + SUM(tools_units) AS TOTAL_UNITS
FROM CLEANED
GROUP BY FILLED_DATE, REGION
ORDER BY FILLED_DATE ASC, REGION DESC, TOTAL_UNITS DESC
```

**설명:**  

`GROUP BY`에서 집계되지 않은 원시 값을 더하는 대신, 각 컬럼을 `SUM()`한 후 더해주는 방식입니다.  
이 방식이 SQL 문법상 더 안정적이고 정확합니다.  

---

## 🟡 문제 6. 전체 데이터를 기준으로 가장 많이 팔린 상품군은 무엇인가요?

**답변:**

```sql
SELECT
  'beverages' AS CATEGORY, SUM(beverages_units) AS TOTAL_UNITS FROM CLEANED
UNION ALL
SELECT 'food', SUM(food_units) FROM CLEANED
UNION ALL
SELECT 'electronics', SUM(electronics_units) FROM CLEANED
UNION ALL
SELECT 'clothes', SUM(clothes_units) FROM CLEANED
UNION ALL
SELECT 'tools', SUM(tools_units) FROM CLEANED
ORDER BY TOTAL_UNITS DESC
LIMIT 1
```

**풀이:**  

* 각 상품군(beverages, food, electronics, clothes, tools)에 대해 `SUM()`을 수행하고, 이를 행(row)으로 나열하기 위해 `UNION ALL`을 사용했습니다.
* `CATEGORY` 열에는 상품군명을 직접 문자열로 명시하고, `TOTAL_UNITS` 열에는 해당 상품군의 총 판매량을 출력합니다.
* 모든 결과를 하나의 테이블처럼 만든 후 `ORDER BY TOTAL_UNITS DESC`로 내림차순 정렬하고, `LIMIT 1`로 가장 많이 팔린 상품군 하나만 추출합니다.

이 방식은 **열을 행으로 전환하는 UNPIVOT 방식**이며, 상품군이 열(column)로 분리되어 있는 테이블에서 **"가장 많이 팔린 상품군"을 찾을 때 가장 많이 사용되는 패턴**입니다.

**풀이 요약:**  

* `SUM()`으로 상품군별 총 판매량 계산
* `UNION ALL`로 열 → 행 구조로 변환
* `ORDER BY DESC LIMIT 1`로 가장 많이 팔린 상품군 추출

**이 외 가능한 정리 쿼리 (모든 상품군 판매량 비교용):**  

```sql
SELECT
  SUM(beverages_units) AS TOTAL_B,
  SUM(food_units) AS TOTAL_F,
  SUM(electronics_units) AS TOTAL_E,
  SUM(clothes_units) AS TOTAL_C,
  SUM(tools_units) AS TOTAL_T
FROM CLEANED
```

**설명:**  

이 쿼리는 각 상품군별 총합만 보여주는 방식입니다. 
어떤 항목이 가장 높은지는 눈으로 비교해야 하기 때문에, **순위 분석이 목적일 경우에는 UNPIVOT 방식이 더 적합합니다.**  

---

## 🟢 문제 7. 모든 날짜, 모든 지역에 대한 평균 배송량을 출력하세요  

**답변:**  

```sql
SELECT
  FILLED_DATE AS DATE,
  REGION,
  AVG(beverages_units) AS TOTAL_B,
  AVG(food_units) AS TOTAL_F,
  AVG(electronics_units) AS TOTAL_E,
  AVG(clothes_units) AS TOTAL_C,
  AVG(tools_units) AS TOTAL_T
FROM CLEANED
GROUP BY FILLED_DATE, REGION
ORDER BY FILLED_DATE, REGION
```

**풀이:**  

* 전처리된 데이터 `CLEANED`를 기준으로, 날짜(`FILLED_DATE`)와 지역(`REGION`)을 `GROUP BY`로 묶었습니다.
* 각 그룹(날짜+지역)에 대해 `AVG()`를 사용하여 **상품군별 평균 배송 수량**을 계산했습니다.
* 평균 값이므로 소수점이 포함될 수 있으며, 단위는 행(row) 단위 평균입니다.
* `ORDER BY`는 결과를 날짜 오름차순, 지역 오름차순으로 정렬합니다.  

이 쿼리는 실무에서 **시간 단위 트렌드**, **지역 간 평균 비교** 등 다양한 분석 상황에서 자주 사용될 것 같습니다.  

**풀이 요약:**  

* `GROUP BY FILLED_DATE, REGION`으로 그룹화
* 각 상품군에 대해 `AVG()`로 평균 배송량 계산
* 정렬 기준은 날짜 → 지역

**이 외 가능한 확장 쿼리 (전 지역 평균):**  

```sql
SELECT
  FILLED_DATE AS DATE,
  AVG(beverages_units) AS TOTAL_B,
  AVG(food_units) AS TOTAL_F,
  AVG(electronics_units) AS TOTAL_E,
  AVG(clothes_units) AS TOTAL_C,
  AVG(tools_units) AS TOTAL_T
FROM CLEANED
GROUP BY FILLED_DATE
ORDER BY FILLED_DATE
```
 
**설명:**  

지역 구분 없이 **날짜만 기준으로 평균을 계산**하고 싶다면 `GROUP BY`에서 `REGION`을 제외하면 됩니다. 전국 단위 평균치를 보고자 할 때 유용합니다.  


---

## 🟠 문제 8. 옷(clothes)을 가장 많이 배송 받은 지역은 어디인가요?  

**답변:**  

```sql
SELECT 
  REGION, 
  SUM(clothes_units) AS TOTAL_C 
FROM CLEANED 
GROUP BY REGION
ORDER BY TOTAL_C DESC 
LIMIT 1
```

**풀이:**  

* 전처리된 `CLEANED` 데이터셋을 기준으로 모든 행을 대상으로 집계합니다.
* `GROUP BY REGION`을 사용해 지역별로 데이터를 묶고,
* 각 지역에 대해 `clothes_units`의 총합을 `SUM(clothes_units)`으로 계산합니다.
* 그 결과를 `ORDER BY TOTAL_C DESC`로 내림차순 정렬하면, 옷 배송량이 많은 지역이 위로 정렬됩니다.
* `LIMIT 1`을 사용해 가장 많은 지역 한 개만 추출합니다.  

이 패턴은 **Top-N 분석**에서 가장 많이 쓰이는 기본 구조입니다.  
정렬 기준을 바꾸면 최소값 분석에도 응용할 수 있습니다.  

**풀이 요약:**  

* `GROUP BY REGION`으로 지역별로 묶고
* `SUM(clothes_units)`으로 총합 계산
* `ORDER BY DESC LIMIT 1`로 가장 많이 받은 지역 1개 추출

**이 외 가능한 확장 쿼리 (전체 순위 확인용):**  

```sql
SELECT
  REGION,
  SUM(clothes_units) AS TOTAL_C
FROM CLEANED
GROUP BY REGION
ORDER BY TOTAL_C DESC
```

**설명:**  

`LIMIT` 없이 모든 지역의 옷 배송량을 내림차순으로 정렬해서 **순위 전체를 확인할 수 있는 쿼리**입니다.  
리포트 작성이나 상위 N개 비교가 필요한 경우 유용합니다.  

---

* **데이터 정제, 분석, 윈도우 함수, 집계 함수, 조건부 집계** 등 다양한 주제를 포함하고 있습니다.
* 실무에서 자주 쓰이는 패턴을 반복 학습하기 위한 목적으로 복기한 내용입니다.
* 데이터베이스로는 PostgreSQL, BigQuery, Snowflake 등을 기준으로 작성되었습니다.

