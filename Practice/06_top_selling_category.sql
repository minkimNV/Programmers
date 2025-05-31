--06_top_selling_category

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

-- 행열 전환 방식, UNPIVOT
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


-- -- 상품군별 총합만 보여주는 방식
-- SELECT
--   SUM(beverages_units) AS TOTAL_B,
--   SUM(food_units) AS TOTAL_F,
--   SUM(electronics_units) AS TOTAL_E,
--   SUM(clothes_units) AS TOTAL_C,
--   SUM(tools_units) AS TOTAL_T
-- FROM CLEANED
