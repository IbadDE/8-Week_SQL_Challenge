

-- How many users are there?
SELECT COUNT(DISTINCT user_id) as number_of_users
FROM users


-- How many cookies does each user have on average?
WITH distinct_tbl as
(SELECT DISTINCT users.user_id, users.cookie_id
FROM Users
JOIN events
ON users.cookie_id = events.cookie_id),
user_cookies as
(SELECT user_id, count(cookie_id) as num_cookies
FROM distinct_tbl
GROUP BY user_id)
SELECT ROUND(AVG(num_cookies),2) as avg_cookies
FROM user_cookies


-- What is the unique number of visits by all users per month?
SELECT EXTRACT(month from event_time) as month_,
		COUNT(DISTINCT users.user_id) as Unique_user
FROM Users
JOIN events
ON users.cookie_id = events.cookie_id
GROUP BY month_
ORDER BY month_


-- What is the number of events for each event type?
SELECT event_type, COUNT(*) as num_events
FROM Events
GROUP BY event_type


-- What is the percentage of visits which have a purchase event?
with tbl_1 as
(SELECT count(event_type) :: decimal
FROM Events),
tbl_2 as
(SELECT event_name,count(1) :: decimal as cnt
FROM events e
JOIN event_identifier ei
on e.event_type = ei.event_type
where event_name = 'Purchase'
GROUP BY event_name)
SELECT event_name, CONCAT(ROUND((cnt/(SELECT * FROM tbl_1))*100,2),' %')
FROM tbl_2


-- What is the percentage of visits which view the checkout page but do not have a purchase event?
with tbl_1 as
(SELECT count(event_type) :: decimal as total
FROM Events),
tbl_2 as
(SELECT ei.event_type,count(1) :: decimal as cnt
FROM events e
JOIN event_identifier ei
on e.event_type = ei.event_type
where ei.event_type in (2,3)
GROUP BY ei.event_type),
tbl_3 as
(SELECT *,(select * from tbl_1),
 		(LAG(cnt) OVER(ORDER BY event_type) - cnt) as diff
FROM tbl_2)
SELECT ROUND((diff/total)*100,2) as checkout_percent
FROM tbl_3
WHERE diff is not null


-- What are the top 3 pages by number of views?
WITH tbl_1 as(
SELECT ph.page_name, count(*) as Total_views
FROM events e
JOIN page_hierarchy ph
ON e.page_id = ph.page_id
GROUP BY ph.page_name),
rnk_tbl as
(SELECT *,
	RANK() OVER(ORDER BY Total_views DESC) as rnk
FROM tbl_1)
SELECT page_name, Total_views
FROM rnk_tbl
WHERE rnk < 4


-- What is the number of views and cart adds for each product category?
WITH all_views as(
SELECT ph.product_category, count(*) as total_views
FROM events e
JOIN page_hierarchy ph
ON e.page_id = ph.page_id
GROUP BY ph.product_category),
add_cart as
(SELECT ph.product_category, count(*) as added_to_cart
FROM events e
JOIN page_hierarchy ph
ON e.page_id = ph.page_id
JOIN event_identifier ei
ON ei.event_type = e.event_type
WHERE ei.event_type = 2
GROUP BY ph.product_category)
SELECT ac.product_category,
		total_views,added_to_cart
FROM all_views av
JOIN add_cart ac
ON av.product_category = ac.product_category


-- What are the top 3 products by purchases?
SELECT ci.products, COUNT(1) as number_of_purchase
FROM Campaign_Identifier ci
JOIN events e
ON e.event_time>ci.start_date and e.event_time<ci.end_date
GROUP BY ci.products
ORDER BY ci.products
