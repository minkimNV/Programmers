with find_code as (
    select
        sum(code) as code
    from skillcodes
    where name in ('Python', 'C#')
)

select
    d.id,
    d.email,
    d.first_name,
    d.last_name
from developers d, find_code c
where d.skill_code & c.code != 0
order by d.id
    
    
