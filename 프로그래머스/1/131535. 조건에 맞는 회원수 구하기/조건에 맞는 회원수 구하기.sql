select count(user_id) as USERS from user_info
# where joined like '2021-%' and 20 <= age <= 29
where date_format(joined, '%Y') like '2021'
and age >= 20 and age <= 29