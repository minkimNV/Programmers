--05_daily_regionwise_totals

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


-- 각 컬럼을 SUM()한 후 더해주는 방식이 SQL 문법상 더 안정적이고 정확하다.
-- SUM(beverages_units) + SUM(food_units) + SUM(electronics_units) + SUM(clothes_units) + SUM(tools_units) AS TOTAL_UNITS
