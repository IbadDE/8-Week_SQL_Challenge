with tbl_1 as
(SELECT u.user_id, e.visit_id,
		e.event_type,e.event_time as visit_start_time
FROM events e 
JOIN users u
ON e.cookie_id = u.cookie_id),
view_tbl as
(SELECT user_id,visit_id,
		COUNT(*) as page_views,
		MIN(visit_start_time) as min_visit_start_time
FROM tbl_1 
WHERE event_type = 1
GROUP BY 1,2),
cart_tbl as
(SELECT user_id,visit_id,
		COUNT(*) as cart_adds
FROM  tbl_1 
WHERE event_type = 2
GROUP BY 1,2),
purchase_tbl as
(SELECT user_id,visit_id,
		COUNT(*) as purchase
FROM  tbl_1 
WHERE event_type = 3
GROUP BY 1,2),
impression_tbl as
(SELECT user_id,visit_id,
		COUNT(*) as impression
FROM  tbl_1 
WHERE event_type = 4
GROUP BY 1,2),
click_tbl as
(SELECT user_id,visit_id,
		COUNT(*) as click
FROM  tbl_1 
WHERE event_type = 5
GROUP BY 1,2),
cnt_tble as
(SELECT vt.user_id,
		vt.visit_id,
		page_views,
		cart_adds,
		purchase,
		impression,
		click,
		min_visit_start_time
FROM cart_tbl ct
FULL outer join view_tbl vt
on vt.visit_id =  ct.visit_id
FULL OUTER JOIN purchase_tbl pt
ON vt.visit_id =  pt.visit_id
FULL OUTER JOIN impression_tbl it
ON vt.visit_id =  it.visit_id
FULL OUTER JOIN click_tbl clt
ON vt.visit_id =  clt.visit_id)
SELECT ci.products,ct.*
FROM cnt_tble as ct
JOIN Campaign_identifier ci
ON ct.min_visit_start_time < ci.end_date and ct.min_visit_start_time > ci.start_date

