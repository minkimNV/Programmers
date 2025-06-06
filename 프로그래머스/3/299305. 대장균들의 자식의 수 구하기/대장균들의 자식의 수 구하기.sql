-- 개체 아이디
-- 개체 아이디의 자식 수

SELECT
    P.ID AS ID,
    COUNT(C.ID) AS CHILD_COUNT
FROM ECOLI_DATA P
LEFT JOIN ECOLI_DATA C ON C.PARENT_ID = P.ID
GROUP BY P.ID
ORDER BY P.ID


# # CTE 방식
# WITH CHILD_COUNT AS (
#     SELECT
#         PARENT_ID,
#         COUNT(ID) AS CHILD_COUNT
#     FROM ECOLI_DATA
#     GROUP BY PARENT_ID
# )

# SELECT
# P.ID AS ID,
# COALESCE(CHILD_COUNT, 0) AS CHILD_COUNT 
# FROM ECOLI_DATA P
# LEFT JOIN CHILD_COUNT C ON P.ID = C.PARENT_ID
# ORDER BY ID