--04_food_than_beverage_days

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
  COUNT(*) AS DAYS
FROM CLEANED
WHERE REGION = 'SIN51'
  AND food_units > beverages_units


-- 그 외 방식
-- SELECT
--   SUM(DAYS) AS DAYS
-- FROM (
--   SELECT
--     CASE WHEN food_units > beverages_units THEN 1
--          ELSE 0
--     END AS DAYS
--   FROM CLEANED
--   WHERE REGION = 'SIN51'
-- )


