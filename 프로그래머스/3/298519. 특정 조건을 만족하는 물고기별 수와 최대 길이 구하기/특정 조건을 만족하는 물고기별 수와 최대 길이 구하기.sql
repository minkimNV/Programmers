

WITH CLEAN AS (
    SELECT
        ID,
        FISH_TYPE,
        CASE WHEN LENGTH IS NULL THEN 10
        ELSE LENGTH
        END AS LENGTH,
        TIME
    FROM FISH_INFO
)

SELECT
COUNT(ID) AS FISH_COUNT,
MAX(LENGTH) AS MAX_LENGTH,
FISH_TYPE
FROM CLEAN
GROUP BY FISH_TYPE
HAVING AVG(LENGTH) >= 33
ORDER BY FISH_TYPE 