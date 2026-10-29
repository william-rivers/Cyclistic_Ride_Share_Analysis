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
  ROUND(AVG(distance_meters), 2) AS avg_distance
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
GROUP BY day_of_week, member_casual
ORDER BY day_of_week, member_casual;



--Step 4: Time of Day Analysis

--Determine the most popular days for members and casuals
--Identify any duration or distance differences between them
SELECT
  member_casual,
  day_of_week,
  COUNT(ride_id) AS ct,
  ROUND(AVG(
    CASE WHEN ride_duration_minutes <= 1440 THEN ride_duration_minutes END
  ), 2) AS avg_duration, --Exclude durations > 24 hours
  ROUND(AVG(distance_meters), 2) AS avg_distance
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share`
GROUP BY day_of_week, member_casual
ORDER BY day_of_week, member_casual;
