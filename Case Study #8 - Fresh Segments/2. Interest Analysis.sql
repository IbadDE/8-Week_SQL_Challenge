
-- Which interests have been present in all month_year dates in our dataset?
WITH month_year as
(SELECT count(DISTINCT(CONCAT(_month,'-',_year))) as month_year
FROM interest_metrics),
interest_cnt as
(SELECT interest_id, count(*) as cnt
FROm interest_metrics
GROUP BY interest_id)
SELECT interest_id
FROM interest_cnt ic
JOIN month_year my
ON ic.cnt = my.month_year
ORDER BY interest_id


-- Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
WITH month_year as
(SELECT count(DISTINCT(CONCAT(_month,'-',_year))) as month_year
FROM interest_metrics),
interest_cnt as
(SELECT interest_id, count(*) as cnt
FROm interest_metrics
GROUP BY interest_id),
same_number as
(SELECT interest_id
FROM interest_cnt ic
JOIN month_year my
ON ic.cnt = my.month_year
ORDER BY interest_id),
tbl_1 as
(SELECT EXTRACT(month from im.month_year) as month_,EXTRACT(year from im.month_year) as year_, SUM(im.composition) as _total
FROM interest_metrics im
JOIN same_number nm
ON im.interest_id = nm.interest_id
GROUP BY month_, year_
ORDER by year_,month_ asc),
tbl_2 as(
SELECT *, SUM(_total) OVER(ORDER BY year_,month_ asc)::Decimal as cum_sum
FROM tbl_1),
tbl_3 as 
(SELECT *,	FIRST_VALUE(cum_sum) OVER(ORDER BY cum_sum desc) as total_sum
FROM tbl_2
order by year_,month_ asc),
tbl_4 as
(SELECT month_,year_, cum_sum, ROUND((cum_sum/total_sum)*100,2) as cum_percent
FROM tbl_3)
SELECT * 
FROM tbl_4
WHERE cum_percent > 90






-- If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
WITH month_year as
(SELECT count(DISTINCT(CONCAT(_month,'-',_year))) as month_year
FROM interest_metrics),
interest_cnt as
(SELECT interest_id, count(*) as cnt
FROM interest_metrics
GROUP BY interest_id),
same_number as
(SELECT interest_id
FROM interest_cnt ic
JOIN month_year my
ON ic.cnt = my.month_year
ORDER BY interest_id)
SELECT (select count(*) FROM interest_metrics) - count(*) as lost_records
FROM same_number sn
JOIN interest_metrics im
ON sn.interest_id = im.interest_id


-- Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
WITH month_year as
(SELECT count(DISTINCT(CONCAT(_month,'-',_year))) as month_year
FROM interest_metrics),
interest_cnt as
(SELECT interest_id, count(*) as cnt
FROm interest_metrics
GROUP BY interest_id),
same_number as
(SELECT interest_id
FROM interest_cnt ic
JOIN month_year my
ON ic.cnt = my.month_year
ORDER BY interest_id),
tbl_1 as
(SELECT EXTRACT(month from im.month_year) as month_,EXTRACT(year from im.month_year) as year_, SUM(im.composition) as _total
FROM interest_metrics im
JOIN same_number nm
ON im.interest_id = nm.interest_id
GROUP BY month_, year_
ORDER by year_,month_ asc),
tbl_2 as(
SELECT *, SUM(_total) OVER(ORDER BY year_,month_ asc)::Decimal as cum_sum
FROM tbl_1),
tbl_3 as 
(SELECT *,	FIRST_VALUE(cum_sum) OVER(ORDER BY cum_sum desc) as total_sum
FROM tbl_2
order by year_,month_ asc)
SELECT month_,year_, cum_sum, ROUND((cum_sum/total_sum)*100,2) as cum_percent
FROM tbl_3


WITH month_year as
(SELECT count(DISTINCT(CONCAT(_month,'-',_year))) as month_year
FROM interest_metrics),
interest_cnt as
(SELECT interest_id, count(*) as cnt
FROm interest_metrics
GROUP BY interest_id),
same_number as
(SELECT interest_id
FROM interest_cnt ic
JOIN month_year my
ON ic.cnt <> my.month_year
ORDER BY interest_id),
tbl_1 as
(SELECT EXTRACT(month from im.month_year) as month_,EXTRACT(year from im.month_year) as year_, SUM(im.composition) as _total
FROM interest_metrics im
JOIN same_number nm
ON im.interest_id = nm.interest_id
GROUP BY month_, year_
ORDER by year_,month_ asc),
tbl_2 as(
SELECT *, SUM(_total) OVER(ORDER BY year_,month_ asc)::Decimal as cum_sum
FROM tbl_1),
tbl_3 as 
(SELECT *,	FIRST_VALUE(cum_sum) OVER(ORDER BY cum_sum desc) as total_sum
FROM tbl_2
order by year_,month_ asc)
SELECT month_,year_, cum_sum, ROUND((cum_sum/total_sum)*100,2) as cum_percent
FROM tbl_3

-- a higher cumulative percentage in data without 14 months may be desirable.


-- After removing these interests - how many unique interests are there for each month?
WITH month_year as
(SELECT count(DISTINCT(CONCAT(_month,'-',_year))) as month_year
FROM interest_metrics),
interest_cnt as
(SELECT interest_id, count(*) as cnt
FROm interest_metrics
GROUP BY interest_id),
same_number as
(SELECT interest_id
FROM interest_cnt ic
JOIN month_year my
ON ic.cnt <> my.month_year
ORDER BY interest_id)
SELECT (CONCAT(_month,'-',_year)) as month_year, COUNT(DISTINCT sn.interest_id) as interest_id
FROM same_number sn
JOIN interest_metrics im
ON sn.interest_id = im.interest_id
GROUP BY _month,_year
