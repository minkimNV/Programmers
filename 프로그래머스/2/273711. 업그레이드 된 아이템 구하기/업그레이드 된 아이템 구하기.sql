# select
# tn.item_id,
# tn.item_name,
# tn.rarity
# from item_info i
# join item_tree t on i.item_id = t.parent_item_id
# join item_info tn on tn.item_id = t.item_id
# order by 1 desc

SELECT R.ITEM_ID, R.ITEM_NAME, R.RARITY
FROM ITEM_INFO P
JOIN ITEM_TREE T ON P.ITEM_ID = T.PARENT_ITEM_ID
JOIN ITEM_INFO R ON T.ITEM_ID = R.ITEM_ID
WHERE P.RARITY = 'RARE'
ORDER BY 1 DESC;

# select
# t.item_id,
# i.item_name,
# i.rarity
# from item_info i
# join item_tree t on i.item_id = t.item_id
# join item_info tn on tn.item_id = t.parent_item_id
# order by 1 desc