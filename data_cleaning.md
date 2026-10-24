## Setting Up for Data Cleaning
### Upload and Combine csv Files
Six of the files (06/2025, 07/2025, 08/2025, 09/2025, 10/2025, and 05/2026) were over 100 MB and too large to upload
to BigQuery directly and needed to be split into two smaller parts.

```python
# import package and alias
import pandas as pd

# convert the csv files into data frames
df_2025_06 = pd.read_csv(r'C:\Users\river\OneDrive\Desktop\Cyclistic_Case_Study\2025_06_Cyclistic_Data.csv')
df_2025_07 = pd.read_csv(r'C:\Users\river\OneDrive\Desktop\Cyclistic_Case_Study\2025_07_Cyclistic_Data.csv')
df_2025_08 = pd.read_csv(r'C:\Users\river\OneDrive\Desktop\Cyclistic_Case_Study\2025_08_Cyclistic_Data.csv')
df_2025_09 = pd.read_csv(r'C:\Users\river\OneDrive\Desktop\Cyclistic_Case_Study\2025_09_Cyclistic_Data.csv')
df_2025_10 = pd.read_csv(r'C:\Users\river\OneDrive\Desktop\Cyclistic_Case_Study\2025_10_Cyclistic_Data.csv')
df_2026_05 = pd.read_csv(r'C:\Users\river\OneDrive\Desktop\Cyclistic_Case_Study\2026_05_Cyclistic_Data.csv')

# chunk_size is the maximum number of rows per output file; 400000 rows is around 70-80 MB.
chunk_size = 400000 
count=1

# iterate through each data frame and turn each chunk into its own csv
for i in range(0, len(df_2025_06), chunk_size):
    chunk = df_2025_06.iloc[i:i + chunk_size]
    chunk.to_csv("2025_06_Cyclistic_Data_pt_" + str(count) + ".csv", index=False)
    count += 1

count=1
for i in range(0, len(df_2025_07), chunk_size):
    chunk = df_2025_07.iloc[i:i + chunk_size]
    chunk.to_csv("2025_07_Cyclistic_Data_pt_" + str(count) + ".csv", index=False)
    count += 1

count=1
for i in range(0, len(df_2025_08), chunk_size):
    chunk = df_2025_08.iloc[i:i + chunk_size]
    chunk.to_csv("2025_08_Cyclistic_Data_pt_" + str(count) + ".csv", index=False)
    count += 1

count=1
for i in range(0, len(df_2025_09), chunk_size):
    chunk = df_2025_09.iloc[i:i + chunk_size]
    chunk.to_csv("2025_09_Cyclistic_Data_pt_" + str(count) + ".csv", index=False)
    count += 1

count=1
for i in range(0, len(df_2025_10), chunk_size):
    chunk = df_2025_10.iloc[i:i + chunk_size]
    chunk.to_csv("2025_10_Cyclistic_Data_pt_" + str(count) + ".csv", index=False)
    count += 1

count=1
for i in range(0, len(df_2026_05), chunk_size):
    chunk = df_2026_05.iloc[i:i + chunk_size]
    chunk.to_csv("2026_05_Cyclistic_Data_pt_" + str(count) + ".csv", index=False)
    count += 1
```

I then uploaded these chunked files and the 6 unchunked files that were already appropriately sized to BigQuery. I 
created a table called raw_combined_Cyclisitic that contains all rows from each file since I plan to routinely query 
the full data and don't want to use JOINs in every query.

```sql
--Combining the individual files into a single table
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

### Identifying Nulls

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

| column                  | null_count|
|-------------------------|-----------|
| null_ride_id            | 0         |
| null_rideable_type      | 0         |
| null_started_at         | 0         |
| null_ended_at           | 0         |
| null_start_station_name | 1249667   |
| null_start_station_id   | 1249667   |
| nulle_end_station_name  | 1314334   |
| null_end_station_id     | 1314334   |
| null_start_lat          | 0         |
| null_start_lng          | 0         |
| null_end_lat            | 5896      |
| null_end_lng            | 5896      |
| null_member_casual      | 0         |

There are a surprising number of rows containing nulls. I plan to use the latitude and longitude data to assign the 
correct station name and id to fill in some of the missing data. Then I plan to use the station name and id to 
assign latitude and longitude based on the average for the station id.

### Removing Duplicate Rides

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

### Checking Station Name and Id

```sql
---Checking for spelling variations, that the same id always matched the same name, and vice versa
SELECT start_station_name, start_station_id, COUNT(*)
FROM cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic
GROUP BY start_station_name, start_station_id
ORDER BY start_station_name, start_station_id
```

```sql
--Added for easy cross-referencing with the results of the previous query
SELECT DISTINCT start_station_id, start_station_name
FROM cyclistic-500415.Cyclistic_Ride_Data.raw_combined_Cyclistic
ORDER BY start_station_id, start_station_name
```

Both queries were repeated for end_station_name and end_station_id. I came across 
5 classifications of anomalies in these columns.

1) Same station id, slight variation to the station name abbreviation (i.e. Street vs St)
2) Same station id, symbol or number added to the end of the station name (i.e. 1, *, etc.)
3) Same station id, same station name but one is marked archived
4) Same station id, different station name (street intersection always located within 1-2 blocks as determined by Google Maps)
5) Different station id, same station name

The count for each combination was too high to be easily explained as data entry errors. 
I suspect that the changes represent changes to station locations, upgrades to stations, 
and spliting stations into 2 nearby stations which should all be tracked in an internal 
company document that I do not have access to. With access to that information, I would 
use it as a reference to determine whether there are any true errors and whether any of 
these station names/ids need to be combined.

### Cleaning Station Id/Name with Latitude/Longitude
