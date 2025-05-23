select count(n.fish_name) as fish_count
from fish_info f
left join fish_name_info n
on f.fish_type = n.fish_type
where fish_name in ('BASS', 'SNAPPER')