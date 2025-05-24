select 
count(id) as count
from ecoli_data
where
    genotype & 2 = 0 # 2번 형질이 아닌 것
and (genotype & 1 != 0 # 1번 형질인 것
    or
     genotype & 4 != 0) # 3번 형질인 것
     