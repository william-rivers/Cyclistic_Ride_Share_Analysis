-- ========================================================================
-- PROJECT: Ride-Share-Membership-Growth-Marketing-Analysis
-- FILE:    03_business_analysis.sql
-- PURPOSE: Answer business question and provide insight on key objectives
-- WAREHOUSE: Google BigQuery
-- ========================================================================

--Step 1: Overall Statistics

--Summary statistics for ride distance by user type
SELECT
  member_casual,
  ROUND(AVG(distance_meters), 2) AS avg_dist,
  ROUND(STDDEV(distance_meters), 2) AS std_dev_dist,
  ROUND(APPROX_QUANTILES(distance_meters, 4)[OFFSET(0)], 2) AS min_dist,
  ROUND(APPROX_QUANTILES(distance_meters, 4)[OFFSET(1)], 2) AS q1_dist,
  ROUND(APPROX_QUANTILES(distance_meters, 4)[OFFSET(2)], 2) AS q2_dist,
  ROUND(APPROX_QUANTILES(distance_meters, 4)[OFFSET(3)], 2) AS q3_dist,
  ROUND(APPROX_QUANTILES(distance_meters, 4)[OFFSET(4)], 2) AS max_dist
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
GROUP BY member_casual;
```



--Find percent of the total rides that were roundtrips split by user type
SELECT
  member_casual,
  ROUND(COUNT(CASE WHEN distance_meters = 0 THEN member_casual END)
    / NULLIF(COUNT(member_casual), 0) * 100, 2) AS pct_rnd_trip,
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
GROUP BY member_casual;



--Summary statistics for ride duration by user type
SELECT
  member_casual,
  ROUND(AVG(ride_duration_minutes), 2) AS avg_time,
  ROUND(STDDEV(ride_duration_minutes), 2) AS std_dev_time,
  ROUND(APPROX_QUANTILES(ride_duration_minutes, 4)[OFFSET(0)], 2) AS min_time,
  ROUND(APPROX_QUANTILES(ride_duration_minutes, 4)[OFFSET(1)], 2) AS q1_time,
  ROUND(APPROX_QUANTILES(ride_duration_minutes, 4)[OFFSET(2)], 2) AS q2_time,
  ROUND(APPROX_QUANTILES(ride_duration_minutes, 4)[OFFSET(3)], 2) AS q3_time,
  ROUND(APPROX_QUANTILES(ride_duration_minutes, 4)[OFFSET(4)], 2) AS max_time
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
WHERE ride_duration_minutes <= 1440 --Excluded since bikes cannot be rented > 24 hours
GROUP BY member_casual;



--Summary statistics for ride velocity by user type
SELECT
  member_casual,
  ROUND(AVG(avg_velocity_m_per_s), 2) AS avg_velocity,
  ROUND(STDDEV(avg_velocity_m_per_s), 2) AS std_dev_velocity,
  ROUND(APPROX_QUANTILES(avg_velocity_m_per_s, 4)[OFFSET(0)], 2) AS min_velocity,
  ROUND(APPROX_QUANTILES(avg_velocity_m_per_s, 4)[OFFSET(1)], 2) AS q1_velocity,
  ROUND(APPROX_QUANTILES(avg_velocity_m_per_s, 4)[OFFSET(2)], 2) AS q2_velocity,
  ROUND(APPROX_QUANTILES(avg_velocity_m_per_s, 4)[OFFSET(3)], 2) AS q3_velocity,
  ROUND(APPROX_QUANTILES(avg_velocity_m_per_s, 4)[OFFSET(4)], 2) AS max_velocity
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
WHERE ride_duration_minutes <= 1440 --Excluded since bikes cannot be rented > 24 hours
GROUP BY member_casual;



--Examine duration buckets for classic bikes based on how rides are priced
SELECT 
  CASE WHEN ride_duration_minutes >= 0 AND ride_duration_minutes <= 45 THEN '1) 0-45 min'
    WHEN ride_duration_minutes > 45 AND ride_duration_minutes <= 180 THEN '2) 45 min - 3 hrs'
    WHEN ride_duration_minutes >180 THEN '3) 3+ hrs'
    END AS duration_category, 
  ROUND(100 * COUNT(CASE WHEN member_casual = 'member' THEN member_casual END)
    / SUM(COUNT(CASE WHEN member_casual = 'member' THEN member_casual END)) OVER(), 2) AS pct_member, 
  ROUND(100 * COUNT(CASE WHEN member_casual = 'casual' THEN member_casual END)
    / SUM(COUNT(CASE WHEN member_casual = 'casual' THEN member_casual END)) OVER(), 2) AS pct_casual
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
WHERE rideable_type = 'classic_bike'
GROUP BY 1
ORDER BY 1;



--Examine duration buckets for electric bikes based on how rides are priced
SELECT 
  CASE WHEN ride_duration_minutes >= 0 AND ride_duration_minutes <= 45 THEN '1) 0-45 min'
    WHEN ride_duration_minutes > 45 AND ride_duration_minutes <= 180 THEN '2) 45 min - 3 hrs'
    WHEN ride_duration_minutes >180 THEN '3) 3+ hrs'
    END AS duration_category, 
  ROUND(100 * COUNT(CASE WHEN member_casual = 'member' THEN member_casual END)
    / SUM(COUNT(CASE WHEN member_casual = 'member' THEN member_casual END)) OVER(), 2) AS pct_member, 
  ROUND(100 * COUNT(CASE WHEN member_casual = 'casual' THEN member_casual END)
    / SUM(COUNT(CASE WHEN member_casual = 'casual' THEN member_casual END)) OVER(), 2) AS pct_casual
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
WHERE rideable_type = 'electric_bike'
GROUP BY 1
ORDER BY 1;




--Step 2: Seasonality Analysis

--Identify when peak casual usage periods are in the year and when casual usage changes rapidly
WITH avgs AS (
SELECT
  month,
  COUNT(ride_id) AS ct,
  ROUND(AVG(
    CASE WHEN ride_duration_minutes <= 1440 THEN ride_duration_minutes END
    ), 2) AS avg_duration,
  ROUND(AVG(distance_meters), 2) AS avg_distance
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
WHERE member_casual = 'casual'
GROUP BY month
) --Calculate average duration and distance per month

SELECT 
  month,
  ct,
  ROUND(
    (ct - LAG(ct) OVER(ORDER BY month)) / LAG(ct) OVER(ORDER BY month) * 100, 2
  ) AS pct_change_ct, --percent change in number of rides from previous month
  avg_duration,
  ROUND(
    (avg_duration - LAG(avg_duration) OVER(ORDER BY month)) / LAG(avg_duration) OVER(ORDER BY month) * 100, 2
  ) AS pct_change_dur, --percent change in ride duration from previous month
  avg_distance,
  ROUND(
    (avg_distance - LAG(avg_distance) OVER(ORDER BY month)) / LAG(avg_distance) OVER(ORDER BY month) * 100, 2
  ) AS pct_change_dist --percent change in ride distance from previous month
FROM avgs
ORDER BY month;



--Identify when peak member usage periods are in the year and when member usage changes rapidly
WITH avgs AS (
SELECT
  month,
  COUNT(ride_id) AS ct,
  ROUND(AVG(
    CASE WHEN ride_duration_minutes <= 1440 THEN ride_duration_minutes END
    ), 2) AS avg_duration,
  ROUND(AVG(distance_meters), 2) AS avg_distance
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
WHERE member_casual = 'member'
GROUP BY month
) --Calculate average duration and distance per month

SELECT 
  month,
  ct,
  ROUND(
    (ct - LAG(ct) OVER(ORDER BY month)) / LAG(ct) OVER(ORDER BY month) * 100, 2
  ) AS pct_change_ct, --percent change in number of rides from previous month
  avg_duration,
  ROUND(
    (avg_duration - LAG(avg_duration) OVER(ORDER BY month)) / LAG(avg_duration) OVER(ORDER BY month) * 100, 2
  ) AS pct_change_dur, --percent change in ride duration from previous month
  avg_distance,
  ROUND(
    (avg_distance - LAG(avg_distance) OVER(ORDER BY month)) / LAG(avg_distance) OVER(ORDER BY month) * 100, 2
  ) AS pct_change_dist --percent change in ride distance from previous month
FROM avgs
ORDER BY month;



--Step 3: Day of Week Analysis

--Determine the most popular days for members and casuals
--Identify any duration, distance, or velocity differences between them
SELECT
  member_casual,
  day_of_week,
  COUNT(ride_id) AS ct,
  ROUND(AVG(
    CASE WHEN ride_duration_minutes <= 1440 THEN ride_duration_minutes END
  ), 2) AS avg_duration, --Exclude durations > 24 hours
  ROUND(AVG(distance_meters), 2) AS avg_distance,
  ROUND(AVG(
    CASE WHEN ride_duration_minutes <= 1440 THEN avg_velocity_m_per_s END
  ), 2) AS avg_velocity --Exclude durations > 24 hours
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
GROUP BY day_of_week, member_casual
ORDER BY day_of_week, member_casual;



--Step 4: Time of Day Analysis

--Identify the most popular weekday time buckets and ride characteristics for each group
SELECT
  member_casual,
  CASE
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 6 AND 8 THEN '1) Morning Rush'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 9 AND 10 THEN '2) Mid-Morning'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 11 AND 12 THEN '3) Lunch Rush'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 13 AND 15 THEN '4) Mid-Afternoon'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 16 AND 17 THEN '5) Evening Rush'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 18 AND 21 THEN '6) Late Evening'
    ELSE '7) Night'
  END AS time_of_day,
  COUNT(ride_id) AS ct,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY member_casual) * 100, 2) AS pct_of_group_ct, --percent of casuals or members
  ROUND(AVG(
    CASE WHEN ride_duration_minutes <= 1440 THEN ride_duration_minutes END
  ), 2) AS avg_duration, --Exclude durations > 24 hours
  ROUND(AVG(distance_meters), 2) AS avg_distance,
  ROUND(AVG(
    CASE WHEN ride_duration_minutes <= 1440 THEN avg_velocity_m_per_s END
  ), 2) AS avg_velocity --Exclude durations > 24 hours
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
WHERE day_of_week BETWEEN 2 AND 6 --Weekdays only
GROUP BY member_casual, time_of_day
ORDER BY member_casual, time_of_day;



--Identify most popular weekend time buckets and ride characteristics for each group
SELECT
  member_casual,
  CASE
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 6 AND 8 THEN '1) Morning Rush'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 9 AND 10 THEN '2) Mid-Morning'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 11 AND 12 THEN '3) Lunch Rush'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 13 AND 15 THEN '4) Mid-Afternoon'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 16 AND 17 THEN '5) Evening Rush'
    WHEN EXTRACT(HOUR FROM started_at) BETWEEN 18 AND 21 THEN '6) Late Evening'
    ELSE '7) Night'
  END AS time_of_day,
  COUNT(ride_id) AS ct,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY member_casual) * 100, 2) AS pct_of_group_ct, --percent of casuals or members
  ROUND(AVG(
    CASE WHEN ride_duration_minutes <= 1440 THEN ride_duration_minutes END
  ), 2) AS avg_duration,
  ROUND(AVG(distance_meters), 2) AS avg_distance,
  ROUND(AVG(
    CASE WHEN ride_duration_minutes <= 1440 THEN avg_velocity_m_per_s END
  ), 2) AS avg_velocity
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
WHERE day_of_week = 1 OR day_of_week = 7 --Weeknds only
GROUP BY member_casual, time_of_day
ORDER BY member_casual, time_of_day;



--Step 5: Bike Type Analysis

--Overall rideable type breakdown by user type
SELECT
  member_casual,
  rideable_type,
  ROUND(
    COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY member_casual) * 100, 2
  ) AS pct_of_group_ct, --percent of rideable type for each user type
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
GROUP BY member_casual, rideable_type
ORDER BY member_casual, rideable_type;



--Season-by-season rideable type breakdown by user type
WITH season_data AS (
  SELECT
    CASE WHEN month BETWEEN 3 AND 5 THEN '1) Spring'
      WHEN month BETWEEN 6 AND 8 THEN '2) Summer'
      WHEN month BETWEEN 9 AND 10 THEN '3) Autumn'
      ELSE '4) Winter'
    END AS season,
    member_casual,
    rideable_type
  FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
) --Create the season column for display and partitioning

SELECT
  *,
  ROUND(
    COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY season, member_casual) * 100, 2
  ) AS pct_of_group_ct, --percent of rideable type for each user type in the given season
FROM season_data
GROUP BY season, member_casual, rideable_type
ORDER BY season, member_casual, rideable_type;



--Step 6: Station Analysis

--Determine the most used stations for each user type
SELECT
    member_casual,
    station_id,
    COUNT(*) AS num_rides,
    DENSE_RANK() OVER(PARTITION BY member_casual ORDER BY COUNT(*) DESC) as station_rk
    -- Dense rank to avoid ties
FROM (
    SELECT member_casual, start_station_id AS station_id
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
    WHERE start_station_id IS NOT NULL
    UNION ALL
    SELECT member_casual, end_station_id AS station_id
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
    WHERE end_station_id IS NOT NULL
) --Group start and end station data
GROUP BY member_casual, station_id
QUALIFY station_rk <= 10 --Keep only top 10 from the window function;



--Display top 10 for casuals and members along with their corresponding rank for the other group
WITH all_rk AS (
  SELECT
    member_casual,
    station_id,
    COUNT(*) AS num_rides,
    DENSE_RANK() OVER(PARTITION BY member_casual ORDER BY COUNT(*) DESC) as station_rk
    -- Dense rank to avoid ties
  FROM (
    SELECT member_casual, start_station_id AS station_id
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
    WHERE start_station_id IS NOT NULL
    UNION ALL
    SELECT member_casual, end_station_id AS station_id
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
    WHERE end_station_id IS NOT NULL
  ) --Group start and end station data
  GROUP BY member_casual, station_id
), --Build the full list of casual and member ranks

split_rk AS (
  SELECT
    station_id,
    MAX(CASE WHEN member_casual = 'casual' THEN station_rk END) AS casual_rk,
    MAX(CASE WHEN member_casual = 'casual' THEN num_rides END) AS casual_rides,
    MAX(CASE WHEN member_casual = 'member' THEN station_rk END) AS member_rk,
    MAX(CASE WHEN member_casual = 'member' THEN num_rides END) AS member_rides,
  FROM all_rk
  GROUP BY station_id
) --Pivot so that casual and member rank/rides are their own columns

SELECT --Build Casual Top 10 List
  'Casual Top 10' as list,
  station_id,
  casual_rk,
  casual_rides,
  member_rk,
  member_rides
FROM split_rk
WHERE casual_rk <= 10
UNION ALL
SELECT --Build Member Top 10 List
  'Member Top 10' as list,
  station_id,
  casual_rk,
  casual_rides,
  member_rk,
  member_rides
FROM split_rk
WHERE member_rk <= 10
ORDER BY
  CASE WHEN list = 'Casual Top 10' THEN 1 ELSE 2 END, --Put casual list first
  CASE WHEN list = 'Casual Top 10' THEN casual_rk ELSE member_rk END --Order each list by rank;



--Identify any stations that fall into both group's top 50 and are member dominated
--This table will be saved and used to generate a map of these stations' locations 
WITH src AS (
  SELECT member_casual, start_station_id AS station_id, start_lat AS lat, start_lng AS lng
  FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
  WHERE start_station_id IS NOT NULL
  UNION ALL
  SELECT member_casual, end_station_id AS station_id, end_lat AS lat, end_lng AS lng
  FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
  WHERE end_station_id IS NOT NULL
), --Combine start and end station data together

all_rk AS (
  SELECT
    member_casual,
    station_id,
    COUNT(*) AS num_rides,
    DENSE_RANK() OVER(PARTITION BY member_casual ORDER BY COUNT(*) DESC) AS station_rk
    -- Dense rank to avoid ties
  FROM src
  GROUP BY member_casual, station_id
), --Build the full list of casual and member ranks

split_rk AS (
  SELECT
    station_id,
    MAX(CASE WHEN member_casual = 'casual' THEN station_rk END) AS casual_rk,
    MAX(CASE WHEN member_casual = 'casual' THEN num_rides END) AS casual_rides,
    MAX(CASE WHEN member_casual = 'member' THEN station_rk END) AS member_rk,
    MAX(CASE WHEN member_casual = 'member' THEN num_rides END) AS member_rides,
  FROM all_rk
  GROUP BY station_id
), --Pivot so that casual and member rank/rides are their own columns

geo AS (
  SELECT
    station_id,
    ROUND(AVG(lat), 4) AS lat,
    ROUND(AVG(lng), 4) AS lng
  FROM src
  GROUP BY station_id
) --Find the average coordinate for each station

SELECT --Build list of high ROI stations
  s.station_id,
  g.lat,
  g.lng,
  s.casual_rk,
  s.casual_rides,
  s.member_rk,
  s.member_rides,
  ROUND(s.member_rides/s.casual_rides, 2) AS mem_cas_ratio
FROM split_rk s
LEFT JOIN geo g
  ON s.station_id = g.station_id
WHERE s.casual_rk <= 50
  AND s.member_rk <= 50
  AND s.member_rides > s.casual_rides --Member dominated
ORDER BY mem_cas_ratio DESC --Highest difference first;
