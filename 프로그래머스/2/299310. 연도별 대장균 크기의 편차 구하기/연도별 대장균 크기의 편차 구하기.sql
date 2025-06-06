SELECT
YEAR(DIFFERENTIATION_DATE) AS YEAR,
(M.MAX_SIZE - SIZE_OF_COLONY) AS YEAR_DEV,
ID
FROM ECOLI_DATA E
LEFT JOIN (
    SELECT
    YEAR(DIFFERENTIATION_DATE) AS YEAR,
    MAX(SIZE_OF_COLONY) AS MAX_SIZE
    FROM ECOLI_DATA
    GROUP BY YEAR(DIFFERENTIATION_DATE)
) AS M
ON YEAR(E.DIFFERENTIATION_DATE) = M.YEAR
ORDER BY YEAR, YEAR_DEV