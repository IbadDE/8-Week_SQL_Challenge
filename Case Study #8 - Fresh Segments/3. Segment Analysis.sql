WITH tbl_1 as
(SELECT interest_id, count(1) as count_interest
FROM interest_metrics
GROUP BY interest_id),
tbl_2 as 
(SELECT im.interest_id,im.composition,
	EXTRACT(month from month_year) as month_,
	EXTRACT(year from month_year) as year_
FROM tbl_1 as tbl
JOIN interest_metrics as im
ON tbl.interest_id = im.interest_id
WHERE count_interest > 5),
tbl_3 as
(SELECT *, 
	RANK() OVER( ORDER BY composition DESC) as mx_rank,
	RANK() OVER( ORDER BY composition ASC) as mn_rank
FROM tbl_2)
SELECT year_,month_,composition
FROM tbl_3
WHERE mx_rank between 1 and 10 or mn_rank between 1 and 10



WITH tbl_1 AS
(SELECT interest_id, AVG(composition) as avg_com
FROM interest_metrics
GROUP BY interest_id),
tbl_2 as
(SELECT interest_id, RANK() OVER(ORDER BY avg_com) as rnk
FROM tbl_1)
SELECT interest_id,rnk FROM tbl_2
WHERE rnk < 6 



SELECT *
FROM interest_metrics
where percentile_ranking is null



WITH tbl_1 AS
(SELECT interest_id, STDDEV(percentile_ranking) as std
FROM interest_metrics
GROUP BY interest_id),
tbl_2 as 
(SELECT interest_id, RANK() OVER(ORDER BY std DESC) as rnk,std
FROM tbl_1
where std is not null)
SELECT interest_id,rnk
FROM tbl_2
WHERE rnk < 6 






WITH tbl_1 AS
(SELECT interest_id, STDDEV(percentile_ranking) as std
FROM interest_metrics
GROUP BY interest_id),
tbl_2 as 
(SELECT interest_id, RANK() OVER(ORDER BY std DESC) as rnk,std
FROM tbl_1
where std is not null),
tbl_3 as
(SELECT EXTRACT(month from month_year) as month_,
		EXTRACT(year from month_year) as year_,
 			tb.interest_id,std,rnk,percentile_ranking
FROM tbl_2 tb
JOIN interest_metrics im
ON im.interest_id = tb.interest_id
WHERE rnk < 6),
tbl_4 as
(SELECT interest_id,std,rnk,percentile_ranking,
 		RANK() OVER(PARTITION BY interest_id ORDER BY percentile_ranking) as mn_rnk,
 		RANK() OVER(PARTITION BY interest_id ORDER BY percentile_ranking DESC) as mx_rnk
FROM tbl_3) 
SELECT *
FROM tbl_4
WHERE mn_rnk =1 or mx_rnk=1
ORDER by interest_id






