with ranked as (
    select
    id,
    size_of_colony,
    ROW_NUMBER() over (order by size_of_colony desc) as rn,
    count(*) over () as total_rows
    from ecoli_data
)

, classified as (
    select
    id,
    case
        when rn <= total_rows * 0.25 then 'CRITICAL'
        when rn <= total_rows * 0.50 then 'HIGH'
        when rn <= total_rows * 0.75 then 'MEDIUM'
    else 'LOW'
    end as colony_name
    from ranked
)

select *
from classified
order by 1