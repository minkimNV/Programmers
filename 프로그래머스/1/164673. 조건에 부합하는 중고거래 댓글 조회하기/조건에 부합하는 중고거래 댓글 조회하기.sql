select title, b.board_id as board_id, reply_id, r.writer_id as writer_id, r.contents as contents, date_format(r.created_date, '%Y-%m-%d') as created_date
from used_goods_board b
inner join used_goods_reply r
on b.board_id = r.board_id
where date_format(b.created_date, '%Y-%m') = '2022-10'
order by r.created_date, title
