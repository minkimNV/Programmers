-- 입양을 간 동물
-- where animal_id in (select animal_id from animal_outs)

-- 보호기간이 가장 길었던
-- MAX outs.datetime - ins.datetime + 1

-- id, name
-- stay desc

SELECT
I.ANIMAL_ID,
I.NAME
FROM ANIMAL_INS I
JOIN ANIMAL_OUTS O ON I.ANIMAL_ID = O.ANIMAL_ID
ORDER BY DATEDIFF(O.DATETIME, I.DATETIME) + 1 DESC
LIMIT 2


-- WITH CLEAN AS (
--     SELECT
--     I.ANIMAL_ID,
--     I.NAME,
--     DATEDIFF(O.DATETIME, I.DATETIME) + 1 AS STAY
--     FROM ANIMAL_INS I
--     JOIN ANIMAL_OUTS O ON I.ANIMAL_ID = O.ANIMAL_ID
-- )

-- SELECT
-- ANIMAL_ID,
-- NAME
-- FROM CLEAN
-- ORDER BY STAY DESC
-- LIMIT 2
