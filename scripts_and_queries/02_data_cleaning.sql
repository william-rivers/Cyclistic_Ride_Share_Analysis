```sql
--Combining the individual files into a single table on BigQuery
--Avoids the being required to do large JOINS for every query

CREATE TABLE `cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic` AS (
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2025_06_Cyclistic_Data_pt_1`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2025_06_Cyclistic_Data_pt_2`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2025_07_Cyclistic_Data_pt_1`

    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2025_07_Cyclistic_Data_pt_2`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2025_08_Cyclistic_Data_pt_1`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2025_08_Cyclistic_Data_pt_2`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2025_09_Cyclistic_Data_pt_1`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2025_09_Cyclistic_Data_pt_2`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2025_10_Cyclistic_Data_pt_1`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2025_10_Cyclistic_Data_pt_2`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2025_11_Cyclistic_Data`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2025_12_Cyclistic_Data`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2026_01_Cyclistic_Data`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2026_02_Cyclistic_Data`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2026_03_Cyclistic_Data`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2026_04_Cyclistic_Data`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2026_05_Cyclistic_Data_pt_1`
    
    UNION ALL
    
    SELECT *
    FROM `cyclistic-500415.Cyclistic_Ride_Data.2026_05_Cyclistic_Data_pt_2`
)
```

```sql
--Identifying any nulls that may need to be addressed or removed
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
FROM `cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic`
```

```sql
--Checking for number of duplicate records
SELECT ride_id, COUNT(ride_id)
FROM cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic
GROUP BY ride_id
HAVING COUNT(ride_id) > 1
ORDER BY COUNT(ride_id) DESC
```

```sql
--Examining the 35 duplicates to ensure they can be removed
SELECT *
FROM cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic
WHERE ride_id IN (
  SELECT ride_id
  FROM cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic
  GROUP BY ride_id
  HAVING COUNT(ride_id) > 1
)
ORDER BY ride_id
```

```sql
--Creating a backup table as a safety measure
CREATE OR REPLACE TABLE cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic_backup AS (
  SELECT *
  FROM cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic
)
```

```sql
--Removing duplicate rides
CREATE OR REPLACE TABLE cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic AS
SELECT * EXCEPT(row_num)
FROM (
  SELECT *,
  ROW_NUMBER() OVER (
    PARTITION BY ride_id
  ) as row_num
  FROM cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic
)
WHERE row_num = 1;
```


```sql
---Checking for spelling variations, that the same id always matched the same name, and vice versa
SELECT start_station_name, start_station_id, COUNT(*)
FROM cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic
GROUP BY start_station_name, start_station_id
ORDER BY start_station_name, start_station_id
```

```sql
--Swapped the order for easy cross-referencing with the results of the previous query
SELECT DISTINCT start_station_id, start_station_name
FROM cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic
ORDER BY start_station_id, start_station_name
```
