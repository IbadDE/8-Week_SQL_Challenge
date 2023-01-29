
---------------------------------------------------------------- Data Exploration and Cleansing ------------------------------------------------------------------


--1: Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
ALTER TABLE interest_metrics
ALTER COLUMN month_year TYPE DATE USING to_date(month_year, 'YYYY--MM-DD');


--2: What is count of records in the nterest_metrics for each month_year value sorted in chronological order 
--   (earliest to latest) with the null values appearing first?
SELECT month_year,
		COUNT(*) as CNT
FROM interest_metrics
GROUP BY month_year;


--3: What do you think we should do with these null values in the fresh_segments.interest_metrics
SELECT *
FROM interest_metrics
WHERE month_year is null;

DELETE FROM interest_metrics
WHERE month_year is null;


--4: How many interest_id values exist in the fresh_segments.interest_metrics table 
--   but not in the fresh_segments.interest_map table? What about the other way around?
(SELECT COUNT(DISTINCT id) as interst_id_map, (SELECT COUNT(DISTINCT interest_id) as interst_id_metrics FROM interest_metrics)
FROM interest_map)


--5:Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT interest_id,
		COUNT(*) as total_record
FROM interest_metrics
GROUP BY interest_id;


--6: What sort of table join should we perform for our analysis and why? Check your logic by checking the rows
--   where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics
--   and all columns from fresh_segments.interest_map except from the id column.
ALTER TABLE interest_metrics
ALTER COLUMN interest_id TYPE integer USING CAST(interest_id as integer);

DROP TABLE IF EXISTS complete_tbl;
CREATE TABLE complete_tbl as (
SELECT me._month,
		me._year,
		me.month_year,
		me.interest_id,
		me.composition,
		me.index_value,
		me.ranking,
		me.percentile_ranking,
		ma.interest_name,
		ma.interest_summary,
		ma.created_at,
		ma.last_modified
FROM interest_metrics me
	JOIN interest_map ma
	ON ma.id = me.interest_id);

SELECT *
FROM complete_tbl


--7: Are there any records in your joined table where the month_year value is before the created_at value from the 
--   fresh_segments.interest_map table? Do you think these values are valid and why?
SELECT *
FROM complete_tbl
WHERE created_at > month_year


-- We will leave at the way it's. Because in month year the date wasn't there. It was us who make the date from 1st of date.



select * from interest_map
select * from interest_metrics
select * from json_data