select f.flavor from first_half f inner join icecream_info i on f.flavor = i.flavor
where total_order >= 3000 and ingredient_type = 'fruit_based'