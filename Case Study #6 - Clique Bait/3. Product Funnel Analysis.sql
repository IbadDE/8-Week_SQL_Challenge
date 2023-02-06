
-- Using a single SQL query - create a new output table which has the following details:
-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased?
DROP TABLE IF EXISTS funnel_tbl;
CREATE TABLE funnel_tbl as
(WITH required_tbl as 
 (SELECT ci.products,e.event_type,
		count(*) as cnt
FROM events e
JOIN Campaign_Identifier ci
ON ci.start_date < e.event_time AND ci.end_date > e.event_time
GROUP BY 1,2),
viewed_tbl as(
SELECT products, cnt as viewed
FROM required_tbl
WHERE event_type = 1),
add_cart_tbl as
(SELECT products, cnt as added_to_cart
FROM required_tbl
WHERE event_type = 2),
purchase_tbl as
(SELECT products, cnt as purchase
FROM required_tbl
WHERE event_type = 3)
SELECT v.products,viewed,added_to_cart,purchase,added_to_cart - purchase as abondend
FROM viewed_tbl v
JOIN add_cart_tbl a
on v.products = a.products
JOIN purchase_tbl p
ON p.products = v.products)


-- Which product had the most views, cart adds and purchases?
with ranking as
(SELECT products,viewed,added_to_cart,purchase,
	RANK() OVER(ORDER BY viewed DESC) rank_1,
	RANK() OVER(ORDER BY added_to_cart DESC) rank_2,
	RANK() OVER(ORDER BY purchase DESC) rank_3
FROM funnel_tbl)
SELECT products,viewed,added_to_cart,purchase
FROM ranking
WHERE rank_1 = 1 or rank_2 = 1 or rank_3 =1


-- Which product was most likely to be abandoned?
WITH tbl_1 as
(SELECT products, ROUND(((abondend::decimal)/(added_to_cart::decimal)*100),2) as abonding_percent
FROM funnel_tbl),
tbl_2 as
(SELECT Products,abonding_percent,RANK() OVER(ORDER BY abonding_percent DESC) as rnk
FROM tbl_1)
SELECT Products,abonding_percent
FROM tbl_2
WHERE rnk=1


-- Which product had the highest view to purchase percentage?
WITH tbl_1 as
(SELECT products, ROUND(((purchase::decimal)/(viewed::decimal)*100),2) as buying_percent
FROM funnel_tbl),
tbl_2 as
(SELECT Products,buying_percent,RANK() OVER(ORDER BY buying_percent DESC) as rnk
FROM tbl_1)
SELECT Products,buying_percent
FROM tbl_2
WHERE rnk=1


-- What is the average conversion rate from view to cart add?
SELECT ROUND(AVG((viewed - added_to_cart)::decimal/viewed::decimal)*100,2) as add_cart_rate
FROM funnel_tbl

		
-- What is the average conversion rate from cart add to purchase?
SELECT ROUND(AVG((added_to_cart - purchase)::decimal/added_to_cart::decimal)*100,2) as buying_rate
FROM funnel_tbl


