-- ====================================================================
-- PROJECT: Ride-Share-Membership-Growth-Marketing-Analysis
-- FILE:    02_data_cleaning.sql
-- PURPOSE: Remove duplicates, standardize strings, and handle nulls
-- WAREHOUSE: Google BigQuery
-- ====================================================================


--Step 1: Combine the individual files into a single table
CREATE TABLE ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share AS (
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2025_06_ride_share_data_pt_1
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2025_06_ride_share_data_pt_2
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2025_07_ride_share_data_pt_1
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2025_07_ride_share_data_pt_2
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2025_08_ride_share_data_pt_1
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2025_08_ride_share_data_pt_2
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2025_09_ride_share_data_pt_1
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2025_09_ride_share_data_pt_2
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2025_10_ride_share_data_pt_1
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2025_10_ride_share_data_pt_2
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2025_11_ride_share_data
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2025_12_ride_share_data
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2026_01_ride_share_data
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2026_02_ride_share_data
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2026_03_ride_share_data
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2026_04_ride_share_data
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2026_05_ride_share_data_pt_1
    UNION ALL
    SELECT *
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.2026_05_ride_share_data_pt_2
);



--Step 2: Find any nulls that may need to be addressed or removed
SELECT
    COUNTIF(ride_id IS NULL OR ride_id = '') AS null_ride_id,
    COUNTIF(rideable_type IS NULL OR rideable_type = '') AS null_rideable_type,
    COUNTIF(started_at IS NULL) AS null_started_at,
    COUNTIF(ended_at IS NULL) AS null_ended_at,
    COUNTIF(start_station_name IS NULL OR start_station_name = '') AS null_start_station_name,
    COUNTIF(start_station_id IS NULL OR start_station_id = '') AS null_start_station_id,
    COUNTIF(end_station_name IS NULL OR end_station_name = '') AS null_end_station_name,
    COUNTIF(end_station_id IS NULL OR end_station_id = '') AS null_end_station_id,
    COUNTIF(start_lat IS NULL) AS null_start_lat,
    COUNTIF(start_lng IS NULL) AS null_start_lng,
    COUNTIF(end_lat IS NULL) AS null_end_lat,
    COUNTIF(end_lng IS NULL) AS null_end_lng,
    COUNTIF(member_casual IS NULL OR member_casual = '') AS null_member_casual
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`;



--Step 3: Check for duplicate records
--Determine number of duplicate records
SELECT ride_id, COUNT(ride_id)
FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
GROUP BY ride_id
HAVING COUNT(ride_id) > 1
ORDER BY COUNT(ride_id) DESC;



--Examine the 35 duplicates to ensure they can be removed
SELECT *
FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
WHERE ride_id IN (
  SELECT ride_id
  FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
  GROUP BY ride_id
  HAVING COUNT(ride_id) > 1
)
ORDER BY ride_id;

--Create a backup table as a safety measure
CREATE OR REPLACE TABLE ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share_backup AS (
  SELECT *
  FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
);



--Remove duplicate rides
CREATE OR REPLACE TABLE ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share AS (
    SELECT * EXCEPT(row_num)
    FROM (
      SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY ride_id
      ) as row_num
      FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
    )
    WHERE row_num = 1
);



--Step 4: Check for spelling variations, that the same id always matched the same name, and vice versa
SELECT start_station_name, start_station_id, COUNT(*)
FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
GROUP BY start_station_name, start_station_id
ORDER BY start_station_name, start_station_id;



--Swapped the order for easy cross-referencing with the results of the previous query
SELECT DISTINCT start_station_id, start_station_name
FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
ORDER BY start_station_id, start_station_name;



--Step 5: Assign nearest station within reason as the station id to fill nulls
--Decide on the appropriate distance from the station average that should still belong to the station
WITH station_avgs AS (
  SELECT 
    start_station_id,
    start_station_name,
    ST_GEOGPOINT(AVG(start_lng), AVG(start_lat)) AS station_point
  FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
  WHERE start_station_id IS NOT NULL 
    AND start_lat IS NOT NULL 
    AND start_lng IS NOT NULL
  GROUP BY start_station_id, start_station_name
), --Calculate the average from each station where there are no null coordinates

distinct_missing_locs AS (
  SELECT 
    ROW_NUMBER() OVER() AS location_id, --Needed for partitioning in the next CTE
    start_lat,
    start_lng
  FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
  WHERE start_station_id IS NULL 
    AND start_lat IS NOT NULL 
    AND start_lng IS NOT NULL
  GROUP BY start_lat, start_lng
), --Group rides with null stations by coordinate so the query executes faster and more efficiently

nearest_station AS (
  SELECT 
    locs.start_lat,
    locs.start_lng,
    ST_DISTANCE(ST_GEOGPOINT(locs.start_lng, locs.start_lat), station_point) AS distance
  FROM distinct_missing_locs locs
  CROSS JOIN station_avgs s --CROSS JOIN to compare each unique coordinate to every station's average point
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY locs.location_id --Cannot partition by a float (start_lat or start_lng)
    ORDER BY ST_DISTANCE(ST_GEOGPOINT(locs.start_lng, locs.start_lat), s.station_point) ASC
  ) = 1 --QUALIFY kept only the station whose average is nearest to each coordinate (rank 1)
)

SELECT 
  CASE 
    WHEN n.distance IS NULL THEN 'Missing Lat/Lng'
    WHEN n.distance < 30 THEN 'Within 30m'
    WHEN n.distance >= 30 AND n.distance < 40 THEN '30m to 40m away'
    WHEN n.distance >= 40 AND n.distance < 50 THEN '40m to 50m away'
    WHEN n.distance >=50 AND n.distance < 60 THEN '50m to 60m away'
    WHEN n.distance >=60 AND n.distance < 70 THEN '60m to 70m away'
    WHEN n.distance >=70 AND n.distance <80 THEN '70m to 80m away'
    WHEN n.distance >=80 AND n.distance <90 THEN '80m to 90m away'
    WHEN n.distance >=90 AND n.distance <100 THEN '90m to 100m away'
    ELSE 'Over 100m away'
  END AS distance_category, --Check each distance band for how many rides fall into each
  COUNT(*) AS total_trips
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share` t
LEFT JOIN nearest_station n
  ON t.start_lat = n.start_lat
 AND t.start_lng = n.start_lng
WHERE t.start_station_id IS NULL
GROUP BY 1
ORDER BY 1;



--Previous qery repeated for end stations
WITH station_avgs AS (
  SELECT 
    start_station_id,
    start_station_name,
    ST_GEOGPOINT(AVG(start_lng), AVG(start_lat)) AS station_point
  FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
  WHERE start_station_id IS NOT NULL 
    AND start_lat IS NOT NULL 
    AND start_lng IS NOT NULL
  GROUP BY start_station_id, start_station_name
), --Calculate the average from each station where there are no null coordinates

distinct_missing_locs AS (
  SELECT 
    ROW_NUMBER() OVER() AS location_id, --Needed for partitioning in the next CTE
    start_lat,
    start_lng
  FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
  WHERE start_station_id IS NULL 
    AND start_lat IS NOT NULL 
    AND start_lng IS NOT NULL
  GROUP BY start_lat, start_lng
), --Group rides with null stations by coordinate so the query executes faster and more efficiently

nearest_station AS (
  SELECT 
    locs.start_lat,
    locs.start_lng,
    ST_DISTANCE(ST_GEOGPOINT(locs.start_lng, locs.start_lat), station_point) AS distance
  FROM distinct_missing_locs locs
  CROSS JOIN station_avgs s ---CROSS JOIN compares each coordinate to all station average points
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY locs.location_id --Cannot partition by a float (start_lat or start_lng)
    ORDER BY ST_DISTANCE(ST_GEOGPOINT(locs.start_lng, locs.start_lat), s.station_point) ASC
  ) = 1 --QUALIFY kept only the station whose average is nearest to each coordinate (rank 1)
)

SELECT 
  CASE 
    WHEN n.distance IS NULL THEN 'Missing Lat/Lng'
    WHEN n.distance < 30 THEN 'Within 30m'
    WHEN n.distance >= 30 AND n.distance < 40 THEN '30m to 40m away'
    WHEN n.distance >= 40 AND n.distance < 50 THEN '40m to 50m away'
    WHEN n.distance >=50 AND n.distance < 60 THEN '50m to 60m away'
    WHEN n.distance >=60 AND n.distance < 70 THEN '60m to 70m away'
    WHEN n.distance >=70 AND n.distance <80 THEN '70m to 80m away'
    WHEN n.distance >=80 AND n.distance <90 THEN '80m to 90m away'
    WHEN n.distance >=90 AND n.distance <100 THEN '90m to 100m away'
    ELSE 'Over 100m away'
  END AS distance_category, --Check each distance band for how many rides fall into each
  COUNT(*) AS total_trips
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share` t
LEFT JOIN nearest_station n
  ON t.start_lat = n.start_lat
 AND t.start_lng = n.start_lng
WHERE t.start_station_id IS NULL
GROUP BY 1
ORDER BY 1;



--Create a backup table as a safety measure
CREATE OR REPLACE TABLE ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share_backup_v2 AS (
  SELECT *
  FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
);



--Fill null station ids within 50 meters of a station with that station's average coordinate
CREATE OR REPLACE TABLE ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share AS (
    WITH station_avgs AS (
      SELECT
        start_station_id,
        start_station_name,
        ST_GEOGPOINT(AVG(start_lng), AVG(start_lat)) AS station_point
      FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
      WHERE start_station_id IS NOT NULL
        AND start_lat IS NOT NULL
        AND start_lng IS NOT NULL
      GROUP BY start_station_id, start_station_name
    ), --Calculate the average from each station where there are no null coordinates
    
    distinct_missing_locs AS (
      SELECT
        ROW_NUMBER() OVER() AS location_id, --Needed for partitioning in the next CTE
        start_lat,
        start_lng
      FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
      WHERE start_station_id IS NULL
        AND start_lat IS NOT NULL
        AND start_lng IS NOT NULL
      GROUP BY start_lat, start_lng
    ), --Group rides with null stations by coordinate so the query executes faster and more efficiently
    
    nearest_station AS (
      SELECT
        locs.start_lat,
        locs.start_lng,
        s.start_station_id AS matched_station_id,
        s.start_station_name AS matched_station_name,
        ST_DISTANCE(ST_GEOGPOINT(locs.start_lng, locs.start_lat), s.station_point) AS distance
      FROM distinct_missing_locs locs
      CROSS JOIN station_avgs s --CROSS JOIN compares each coordinate to all station average points
      QUALIFY ROW_NUMBER() OVER (
        PARTITION BY locs.location_id
        ORDER BY ST_DISTANCE(ST_GEOGPOINT(locs.start_lng, locs.start_lat), s.station_point) ASC
      ) = 1 --QUALIFY kept only the station whose average is nearest to each coordinate (rank 1)
    )
    
    SELECT
      t.* EXCEPT(start_station_id, start_station_name),
      COALESCE(
        t.start_station_id, --Keep station ids already filled
        IF(n.distance <= 50, n.matched_station_id, NULL)
      ) AS start_station_id, --Leave null if the distance is more than 50 meters
      COALESCE(
        t.start_station_name, --Keep station names already filled
        IF(n.distance <= 50, n.matched_station_name, NULL)
      ) AS start_station_name --Leave null if the distance is more than 50 meters
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share t
    LEFT JOIN nearest_station n
       ON t.start_lat = n.start_lat
       AND t.start_lng = n.start_lng
);



--Step 6: Identify any problems in ride duration
--Checking duration buckets to understand the breakdown
WITH time_data AS (
    SELECT ROUND(TIMESTAMP_DIFF(ended_at, started_at, minute),0) AS ride_duration
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
    WHERE started_at IS NOT NULL AND ended_at IS NOT NULL
    ) --Calculates ride duration
    
SELECT
    CASE WHEN ride_duration < 0 THEN 'Negative duration'
    WHEN ride_duration >= 0 AND ride_duration < 2 THEN 'Possible false start'
    WHEN ride_duration >= 2 AND ride_duration < 60 THEN 'Within 1 hour'
    WHEN ride_duration >= 60 AND ride_duration < 180 THEN '1-3 hours'
    WHEN ride_duration >= 180 AND ride_duration < 360 THEN '3-6 hours'
    WHEN ride_duration >= 360 AND ride_duration < 720 THEN '6-12 hours'
    WHEN ride_duration >= 720 AND ride_duration < 1440 THEN '12-24 hours'
    WHEN ride_duration >= 1440 THEN "Over 24 hours"
    END AS time_category, --Creates buckets for comparison
    COUNT(*) AS total_trips
FROM time_data
GROUP BY 1
ORDER BY 2;



--Compare null station id count to rides over 12 hours count
WITH time_data AS (
    SELECT
    start_station_id,
    end_station_id,
    ROUND(TIMESTAMP_DIFF(ended_at, started_at, minute),0) AS ride_duration
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
    WHERE started_at IS NOT NULL AND ended_at IS NOT NULL
    ) --Calculate ride duration
    
SELECT
    COUNTIF(start_station_id IS NULL) AS start_nulls,
    COUNTIF(end_station_id IS NULL) AS end_nulls,
    COUNT(*) AS rides_over_12_hours
FROM time_data
WHERE ride_duration > 720;



 --Compare null station id count to rides over 24 hours count
WITH time_data AS (
    SELECT
    start_station_id,
    end_station_id,
    ROUND(TIMESTAMP_DIFF(ended_at, started_at, minute),0) AS ride_duration
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
    WHERE started_at IS NOT NULL AND ended_at IS NOT NULL
    ) --Calculate ride duration
    
SELECT
    COUNTIF(start_station_id IS NULL) AS start_nulls,
    COUNTIF(end_station_id IS NULL) AS end_nulls,
    COUNT(*) AS rides_over_12_hours
FROM time_data
WHERE ride_duration > 1440;



 --Check whether the stations changed on extremely short rides
WITH time_data AS (
    SELECT
    start_station_id,
    end_station_id,
    ROUND(TIMESTAMP_DIFF(ended_at, started_at, minute),0) AS ride_duration
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
    WHERE started_at IS NOT NULL AND ended_at IS NOT NULL
) --Calculate ride duration
    
SELECT
  COUNT(*) AS ct
FROM time_data
WHERE ride_duration > 0 AND ride_duration < 2
  AND start_station_id != end_station_id;



--When station did not change, was there any difference between members and casuals?
WITH time_data AS (
    SELECT
    start_station_id,
    end_station_id,
    member_casual,
    ROUND(TIMESTAMP_DIFF(ended_at, started_at, minute),0) AS ride_duration
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
    WHERE started_at IS NOT NULL AND ended_at IS NOT NULL
    ) --Calculate ride duration
    
SELECT
  member_casual,
  COUNT(*) AS ct
FROM time_data
WHERE ride_duration > 0 AND ride_duration < 2
  AND start_station_id = end_station_id
GROUP BY member_casual



--Step 7: Identify any issues related to how quickly bikes traveled during the ride
WITH time_data AS (
    SELECT
    rideable_type,
    ROUND(TIMESTAMP_DIFF(ended_at, started_at, second),1) AS ride_duration,
    ST_DISTANCE(ST_GEOGPOINT(start_lng, start_lat), ST_GEOGPOINT(end_lng, end_lat)) AS ride_distance
    FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
    WHERE started_at IS NOT NULL AND ended_at IS NOT NULL AND end_lng IS NOT NULL AND end_lat IS NOT NULL
    ) --Calculate ride duration and distance
    
SELECT --Count rides with speeds that are unrealistically fast
  COUNT(*) AS ct
FROM time_data
WHERE
  CASE
    WHEN ride_duration > 0 AND ride_distance/ride_duration > 8.5 AND rideable_type = 'classic_bike' THEN 1
    WHEN ride_duration > 0 AND ride_distance/ride_duration > 11 AND rideable_type = 'electric_bike' THEN 1
    ELSE 0 --electric bikes have pedal assist which makes high speeds easier to maintain
  END = 1;



---Step 8: Add ride duration, month, day of week, distance, and average velocity columns.
--Also, filter out rides with durations or speeds that are unrealistic for a real ride

--Create a backup table as a safety measure
CREATE OR REPLACE TABLE ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share_backup_v3 AS (
  SELECT *
  FROM ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share
);



CREATE OR REPLACE TABLE `ride-share-500415.Ride_Share_Marketing_Analysis.cleaned_combined_ride_share` AS (
    WITH trips AS (
        SELECT
          ride_id,
          rideable_type,
          started_at,
          ended_at,
          ROUND(TIMESTAMP_DIFF(ended_at, started_at, SECOND) / 60.0, 2) AS ride_duration_minutes,
          EXTRACT(MONTH FROM started_at) AS month,
          EXTRACT(DAYOFWEEK FROM started_at) AS day_of_week,
          start_station_name,
          start_station_id,
          end_station_name,
          end_station_id,
          start_lat,
          start_lng,
          end_lat,
          end_lng,
          ST_DISTANCE(
            ST_GEOGPOINT(start_lng, start_lat),
            ST_GEOGPOINT(end_lng, end_lat)
          ) AS distance_meters,
          ST_DISTANCE(
            ST_GEOGPOINT(start_lng, start_lat),
            ST_GEOGPOINT(end_lng, end_lat)
          ) / NULLIF(TIMESTAMP_DIFF(ended_at, started_at, SECOND),0) AS avg_velocity_m_per_s,
          member_casual
        FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
        WHERE end_lat IS NOT NULL AND end_lng IS NOT NULL
    ) --Create the new columns
        
    SELECT *
    FROM trips
    WHERE ride_duration_minutes > 0 --No negative durations
      AND CASE
          WHEN ride_duration_minutes <= 2
            AND distance_meters > 50 THEN 1
          WHEN ride_duration_minutes <= 2
            AND COALESCE(start_station_id, 'A') != COALESCE(end_station_id, 'B') THEN 1
          WHEN ride_duration_minutes > 2 THEN 1
          ELSE 0
        END = 1 --If durations <= 2 min, needs to travel 50 meters or change station
      AND CASE
          WHEN rideable_type = 'classic_bike'
            AND avg_velocity_m_per_s < 8.5 THEN 1
          WHEN rideable_type = 'electric_bike'
            AND avg_velocity_m_per_s < 11 THEN 1
          ELSE 0
        END = 1 --Speeds should be reasonable for an average velocity
);
