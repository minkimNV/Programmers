SELECT
D.DEPT_ID,
D.DEPT_NAME_EN,
ROUND(AVG(E.SAL), 0) AS AVG_SAL
FROM HR_DEPARTMENT D
INNER JOIN HR_EMPLOYEES E ON D.DEPT_ID = E.DEPT_ID
GROUP BY D.DEPT_ID, D.DEPT_NAME_EN
ORDER BY AVG_SAL DESC


-- 문제 예시에서는 모든 부서가 직원 데이터를 가지고 있지만, 직원이 없는 부서는 결과에 포함되면 안된다.
-- left join 을 쓰면 직원이 없는 부서도 null 평균값으로 평균값을 갖는 것처럼 출력될 수 있다.