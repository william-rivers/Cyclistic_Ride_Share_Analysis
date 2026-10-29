# Ride Share Membership Growth Marketing Analysis

Author: William Rivers

---

## Description
This case study is part of my capstone project for the Google Data Analytics Professional Certificate. My role was 
to work as a data analyst for a fictional company, Cyclistic, and use the six steps of the data analysis process 
(Ask, Prepare, Process, Analyze, Share, and Act) to present my findings on the past year of ride data.

### Scenario
I am a data analyst on the marketing analyst team at Cyclistic, a bike-share company in Chicago. The director of 
marketing believes the company’s future success depends on maximizing the number of annual memberships. Therefore, 
my team wants to understand how casual riders and annual members use Cyclistic bikes differently. From these 
insights, my team will design a new marketing strategy to convert casual riders into annual members.

---

## Step 1: Ask
### 1.1 Business Task

Accelerate revenue and annual membership growth by analyzing aggregate trip metrics to discover distinct usage 
patterns for casual riders and annual members, equipping marketing teams with data-supported profiles needed to 
optimize conversion campaigns.

### 1.2 Key Objectives

1) **Develop Behavioral Profiles**: Segment ride data to isolate casual use that mirrors member behavior.
2) **Optimize Campaign Timing**: Pinpoint high-yield seasonal windows for aggressive marketing by mapping fluctuations in ride volume.
3) **Locate Geographic Hotspots**: Identify high-density stations for high-ROI out-of-home (OOH) advertisements.
4) **Define Conversion Triggers**: Translate clear cost-benefit metrics to establish where annual membership becomes more economical.

### 1.3 Deliverables

1. A clear statement of the business task
2. A description of all data sources used
3. Documentation of any cleaning or manipulation of data
4. A summary of my analysis
5. Supporting visualizations and key findings
6. My top recommendations based on my analysis

### 1.4 Key Stakeholders

* **Director of Marketing**: My manager. Believes that maximizing annual membership is key to the company's success.

* **Marketing analytics team**: A team of data analysts, including me, who are responsible for collecting, analyzing,
  and reporting data that helps guide marketing strategy.

* **Executive team**: The detail-oriented executive team will decide whether to approve the recommended marketing program.

---

## Step 2: Prepare
### 2.1 Data Source Description
The [raw data](https://divvy-tripdata.s3.amazonaws.com/index.html), stripped of personal identifying information, is publicly 
available where Divvy, the real-world counterpart to the fictional company Cyclistic, publishes their records from June 1, 
2020 to present. It is available through Motivate International Inc. under this [license](https://divvybikes.com/data-license-agreement).

The ride data in each file is organized into 13 columns. These columns are ride_id (String), rideable_type (String), 
started_at (TimeStamp), ended_at (TimeStamp), start_station_name (String), start_station_id (String), end_station_name 
(String), end_station_id (String), start_lat (Float), start_lng (Float), end_lat (Float), end_lng (Float), member_casual 
(String). All together, the files represent over 6 million rows with each row representing a single ride. Each file is 
saved in the format YYYY_MM_ride_share_data.

### 2.2 Is Data ROCCC?

1. **Reliable**: The data is generally reliable, but there are many rows with missing fields that I will address in data cleaning.

2. **Original**: The data is original as it was collected and maintained by the source company (first-party source).

3. **Comprehensive**: The data is comprehensive because all fields necessary to identify characteristics of members and casual riders are included.

4. **Current**: The data is current and covers the last year of ride data.

5. **Cited**: The data is citable and was obtained from the company that collected it (first-party source). See source linked above.

Overall, this dataset is considered to be of good quality and can be used to make business recommendations.

---

## Step 3: Process
### 3.1 Upload and Combine csv Files
I specifically wanted my first project to use SQL since it is one of the core skills in any data field. Six of the files 
(06/2025, 07/2025, 08/2025, 09/2025, 10/2025, and 05/2026) were over 100 MB and too large to upload to BigQuery directly. 
The following python script was used to split these files into two smaller parts.

```python
# import package and alias
import pandas as pd

# convert the csv files into data frames
df_2025_06 = pd.read_csv(r'data/raw_data/2025_06_ride_share_data.csv')
df_2025_07 = pd.read_csv(r'data/raw_data/2025_07_ride_share_data.csv')
df_2025_08 = pd.read_csv(r'data/raw_data/2025_08_ride_share_data.csv')
df_2025_09 = pd.read_csv(r'data/raw_data/2025_09_ride_share_data.csv')
df_2025_10 = pd.read_csv(r'data/raw_data/2025_10_ride_share_data.csv')
df_2026_05 = pd.read_csv(r'data/raw_data/2026_05_ride_share_data.csv')

# chunk_size is the maximum number of rows per output file; 400000 rows is around 70-80 MB.
chunk_size = 400000 
count=1

# iterate through each data frame and turn each chunk into its own csv
for i in range(0, len(df_2025_06), chunk_size):
    chunk = df_2025_06.iloc[i:i + chunk_size]
    chunk.to_csv("2025_06_ride_share_data_pt_" + str(count) + ".csv", index=False)
    count += 1

count=1
for i in range(0, len(df_2025_07), chunk_size):
    chunk = df_2025_07.iloc[i:i + chunk_size]
    chunk.to_csv("2025_07_ride_share_data_pt_" + str(count) + ".csv", index=False)
    count += 1

count=1
for i in range(0, len(df_2025_08), chunk_size):
    chunk = df_2025_08.iloc[i:i + chunk_size]
    chunk.to_csv("2025_08_ride_share_data_pt_" + str(count) + ".csv", index=False)
    count += 1

count=1
for i in range(0, len(df_2025_09), chunk_size):
    chunk = df_2025_09.iloc[i:i + chunk_size]
    chunk.to_csv("2025_09_ride_share_data_pt_" + str(count) + ".csv", index=False)
    count += 1

count=1
for i in range(0, len(df_2025_10), chunk_size):
    chunk = df_2025_10.iloc[i:i + chunk_size]
    chunk.to_csv("2025_10_ride_share_data_pt_" + str(count) + ".csv", index=False)
    count += 1

count=1
for i in range(0, len(df_2026_05), chunk_size):
    chunk = df_2026_05.iloc[i:i + chunk_size]
    chunk.to_csv("2026_05_ride_share_data_pt_" + str(count) + ".csv", index=False)
    count += 1
```

I then uploaded these chunked files and the 6 unchunked files that were already appropriately sized to BigQuery. 
To prepare for data cleaning, I used the following query to create a table called raw_combined_ride_share that 
contains all rows from each file. I did this to avoid needing long, multi-joins for most of my queries.

```sql
--Combine the individual files into a single table
CREATE TABLE `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share` AS (
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2025_06_ride_share_data_pt_1`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2025_06_ride_share_data_pt_2`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2025_07_ride_share_data_pt_1`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2025_07_ride_share_data_pt_2`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2025_08_ride_share_data_pt_1`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2025_08_ride_share_data_pt_2`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2025_09_ride_share_data_pt_1`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2025_09_ride_share_data_pt_2`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2025_10_ride_share_data_pt_1`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2025_10_ride_share_data_pt_2`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2025_11_ride_share_data`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2025_12_ride_share_data`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2026_01_ride_share_data`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2026_02_ride_share_data`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2026_03_ride_share_data`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2026_04_ride_share_data`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2026_05_ride_share_data_pt_1`
    UNION ALL
    SELECT *
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.2026_05_ride_share_data_pt_2`
);
```

### 3.2 Identifying Nulls

I started by searching each column for null values and also empty strings in string columns.

```sql
-- Checking nulls in each column
SELECT COUNTIF(ride_id IS NULL OR ride_id = '') AS null_ride_id,
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


While many columns do not contain any null values, there are still over 1 million rows containing nulls. 
I plan to use the latitude and longitude data to assign the correct station name and id to fill in some 
of the missing data. I also planned to use the station name and id to assign latitude and longitude based 
on the average for the station id. First, I needed to identify any duplicate rides and remove them out so 
they do not affect the results.

### 3.3 Removing Duplicate Rides

I started by searching for duplicated ride ids with GROUP BY.

```sql
--Determine number of duplicate records
SELECT ride_id, COUNT(ride_id)
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
GROUP BY ride_id
HAVING COUNT(ride_id) > 1
ORDER BY COUNT(ride_id) DESC;
```

35 ride ids appeared twice. I suspected they were duplicated rides and planned to remove them from the 
table, but visualized them first to make sure.

```sql
--Examine the 35 duplicates to ensure they can be removed
SELECT *
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
WHERE ride_id IN (
  SELECT ride_id
  FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
  GROUP BY ride_id
  HAVING COUNT(ride_id) > 1
)
ORDER BY ride_id;
```

After verifying that these represent duplicated rides, I created a back up table and removed the duplicates 
using the following queries.

```sql
--Create a backup table as a safety measure
CREATE OR REPLACE TABLE `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share_backup` AS (
  SELECT *
  FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
);
```

```sql
--Remove duplicate rides
CREATE OR REPLACE TABLE `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share` AS (
    SELECT * EXCEPT(row_num)
    FROM (
      SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY ride_id
      ) as row_num
      FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
    )
    WHERE row_num = 1
);
```

### 3.4 Checking Station Names and Ids

I also checked start_station_name, start_station_id, end_station_name, and end_station_id to make sure that there 
were no misspellings in the station names and that a station name always corresponded to the same station id. I 
downloaded the results of the two queries that used DISTINCT as Google Sheets to use the filtering in place function 
to more easily identify where two station names corresponded to the same station id.

```sql
--Checking for spelling variations, that the same id always matched the same name, and vice versa
SELECT start_station_name, start_station_id, COUNT(*)
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
GROUP BY start_station_name, start_station_id
ORDER BY start_station_name, start_station_id;
```

```sql
--Swapped the order for easy cross-referencing with the results of the previous query
SELECT DISTINCT start_station_id, start_station_name
FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
ORDER BY start_station_id, start_station_name
```

Both queries were repeated for end_station_name and end_station_id. There was significant, unexplained variation to 
station names in both the start_station_names and end_station_names fields. I came accross 5 classifications of 
anomalies in these columns.

1) Same station id, slight variation to the station name abbreviation (i.e. Street vs St)
2) Same station id, symbol or number added to the end of the station name (i.e. 1, *, etc.)
3) Same station id, same station name but one is marked archived
4) Same station id, different station name (street intersection always located within 1-2 blocks as determined by Google Maps)
5) Different station id, same station name

In each case, the count for each combination was too high to be easily explained as data entry errors. I decided to 
leave the fields as they were since there was too much variation for it to be an accident. I suspect that the 
changes represent changes to station locations, upgrades to stations, and spliting stations into 2 nearby stations 
which should all be tracked in an internal company document that I do not have access to. With access to that 
information, I would use it as a reference to determine whether there are any true errors and whether any of these 
station names/ids need to be combined.

### 3.5 Cleaning Station Id, Station Name, Latitude, and Longitude

First, I created another backup for my table. Next, I identified the average latitute and longitude for each start 
station id and name combination and did some research to find out that the average city block in Chicago is 100 
meters by 200 meters. I ran the following query and an identical query for the end stations to help me understand 
how many of the rides with null station ids and names fall close to a known station. My assumption was that the 
stations would not be larger than 30 meters but I wanted to see the numbers so I could make an informed decision.

```sql
--Decide on the appropriate distance from the station average that should still belong to the station
WITH station_avgs AS (
  SELECT 
    start_station_id,
    start_station_name,
    ST_GEOGPOINT(AVG(start_lng), AVG(start_lat)) AS station_point
  FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
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
  FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
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
```

Start Station Results:
| distance_category | total_trips  |
|-------------------|--------------|
| 30m to 40m away   | 6007         |
| 40m to 50m away   | 9368         |
| 50m to 60m away   | 9454         |
| 60m to 70m away   | 50765        |
| 70m to 80m away   | 20242        |
| 80m to 90m away   | 117217       |
| 90m to 100m away  | 42711        |
| Over 100m away    | 980419       |
| Within 30m        | 13478        |

End Station Results:
| distance_category | total_trips  |
|-------------------|--------------|
| 30m to 40m away   | 6174         |
| 40m to 50m away   | 10013        |
| 50m to 60m away   | 10201        |
| 60m to 70m away   | 45345        |
| 70m to 80m away   | 20754        |
| 80m to 90m away   | 67645        |
| 90m to 100m away  | 94507        |
| Missing Lat/Lng   | 5890         |
| Over 100m away    | 1039124      |
| Within 30m        | 14667        |

I was particularly surprised to find that there were so many trips starting or ending over 100 meters away 
from any identified station since this number represents around one sixth of the total rides in the past 
year. If there are any clusters, they may make excellent locations for new stations. I decided that 50 
meters is an reasonable radius to set so that I don't accidentally pull rides from opposite of the short 
side of blocks. I then created a backup table and assigned a station id and name to rides where the fields 
were NULL and within 50 meters of a station average. 

```sql
--Fill null station ids within 50 meters of a station with that station's average coordinate
CREATE OR REPLACE TABLE `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share` AS (
    WITH station_avgs AS (
      SELECT
        start_station_id,
        start_station_name,
        ST_GEOGPOINT(AVG(start_lng), AVG(start_lat)) AS station_point
      FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
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
      FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
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
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share` t
    LEFT JOIN nearest_station n
       ON t.start_lat = n.start_lat
       AND t.start_lng = n.start_lng
);
```

### 3.6 Cleaning Ride Time and Speed

First, I visualized the rides where the duration of the trip was either negative, indicating an error in 
the started_at and ended_at data, or over 1440 since it is not reasonable to assume that clients rented 
the bikes for more than one day at a time.

```sql
--Checking duration buckets to understand the breakdown
WITH time_data AS (
    SELECT ROUND(TIMESTAMP_DIFF(ended_at, started_at, minute),0) AS ride_duration
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
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
```

| time_category        | total_trips  |
|----------------------|--------------|
| Negative duration    | 29           |
| 6-12 hours           | 1961         |
| 12-24 hours          | 2464         |
| Over 24 hours        | 5836         |
| 3-6 hours            | 6755         |
| 1-3 hours            | 107912       |
| Possible false start | 123771       |
| Zero duration        | 161323       |
| Within 1 hour        | 5438617      |

I suspect that most of the trips over 12 hours are rides where the bikes were left at locations that were 
not a station and that the duration may not represent the actual time that the client left the bike.

```sql
--Compare null station id count to rides over 12 hours count
WITH time_data AS (
    SELECT
        start_station_id,
        end_station_id,
        ROUND(TIMESTAMP_DIFF(ended_at, started_at, minute),0) AS ride_duration
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
    WHERE started_at IS NOT NULL AND ended_at IS NOT NULL
    ) --Calculate ride duration
    
SELECT
    COUNTIF(start_station_id IS NULL) AS start_nulls,
    COUNTIF(end_station_id IS NULL) AS end_nulls,
    COUNT(*) AS rides_over_12_hours
FROM time_data
WHERE ride_duration > 720;
```

| start_nulls | end_nulls | rides_over_12_hours  |
|-------------|-----------|----------------------|
| 0           | 5775      | 8299                 |

I realized that some of these rides might have been captured by my earlier attempts to assign station_names 
so I repeated the query using the backup table. Three rides originally had a null end station and had been 
reassigned to a station on the same block. These three rides may represent clients "abandoning" the bikes 
near a station that is full or that they otherwise are not able to access. I also reran the original query, 
minus the start station id nulls since there were none, looking at only the rides that lasted more than 24 
hours.

| end_nulls | rides_over_24  |
|-----------|----------------|
| 5707      | 5836           |

The 119 rides that were over 24 hours long but have an end station, may be due to the bikes being returned 
to a station but the rides not officially ending either due to user error or equipment malfunction. The 
remainder almost certainly represent stolen bikes or those abandoned at least 50 meters away from any 
station. When analyzing ride duration, I plan to exclude rides over 24 hours when analyzing the ride 
duration so they don't skew the results but I want them included when I look for natural groupings in the 
latitude/longitude data for rides without a station id. The vast majority of the ride durations over 1440 
minutes have a null end station name and end at 1499.0 minutes. I suspect that the timer automatically 
stops at 1499 minutes and the ride automatically ends if the bike has not already been returned.

The large number of rides that lasted betweeon 0 and 2 minutes was surprising. I included that category 
because I have seen people try out a similar company's product and decide that they did not like it without 
traveling anywhere. I expected several rides to fall under that category but over 250,000 was significantly 
higher than expected.

```sql
 --Check whether the stations changed on extremely short rides
WITH time_data AS (
    SELECT
        start_station_id,
        end_station_id,
        ROUND(TIMESTAMP_DIFF(ended_at, started_at, minute),0) AS ride_duration
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
    WHERE started_at IS NOT NULL AND ended_at IS NOT NULL
) --Calculate ride duration
    
SELECT
  COUNT(*) AS ct
FROM time_data
WHERE ride_duration > 0 AND ride_duration < 2
  AND start_station_id != end_station_id;
```

```sql
--When station did not change, was there any difference between members and casuals?
WITH time_data AS (
    SELECT
        start_station_id,
        end_station_id,
        member_casual,
        ROUND(TIMESTAMP_DIFF(ended_at, started_at, minute),0) AS ride_duration
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
    WHERE started_at IS NOT NULL AND ended_at IS NOT NULL
    ) --Calculate ride duration
    
SELECT
  member_casual,
  COUNT(*) AS ct
FROM time_data
WHERE ride_duration > 0 AND ride_duration < 2
  AND start_station_id = end_station_id
GROUP BY member_casual;
```

I found that 57,067 rides had a different start and end station despite the trip length being between 0 and 
2 minutes. Additionally, the number of rides where the start and end stations were the same were very similar 
between members and casual users. I initially suspected that most of this category was made up of people that 
either couldn't figure out how the system worked and gave up or ended up not using the product for a similar 
reason. The fact that members and casuals are similarly represented makes that less likely as members likely 
understand how the system works before purchasing the membership. To exclude rides that seem to have not 
really taken place, I decided to remove all rides with a 0-2 minutes duration where the start and end stations 
were the same or the distance was within 50 meters. Likewise, I decided to remove any rides with a negative or 
zero durations as that indicates likely equipment malfunction.

Lastly, I examined the speed with which the ride seemingly traveled. I researched bike speed and found that 
professional cyclists on flat ground tend to average around 25-30 mph with specialized light-weight bikes and 
that casual cyclists average around 13 mph. Additionally, I learned that the e-bike features a pedal assist that 
allows riders to more easily maintain a high speed but that it cuts off at 20 mph. Additionally, traffic, 
pedestrians, red lights, hills, wind, etc. all lower the maximum safe speed of the bike. Finally, I am using 
straight line distance between the start and end points because I do not have access to route data. The true 
speed would be even higher given that the true distance is higher than the straight line distance. I decided 
to establish a cutoff of 11 m/s (24.6 mph) for e-bikes and 8.5 m/s (19.0 mph) for standard bikes.

```sql
--Identify any issues related to how quickly bikes traveled during the ride
WITH time_data AS (
    SELECT
        rideable_type,
        ROUND(TIMESTAMP_DIFF(ended_at, started_at, second),1) AS ride_duration,
        ST_DISTANCE(ST_GEOGPOINT(start_lng, start_lat), ST_GEOGPOINT(end_lng, end_lat)) AS ride_distance
    FROM `ride-share-500415.Ride_Share_Marketing_Analysis.raw_combined_ride_share`
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
```

I identified 26,069 rides that needed to be excluded from the cleaned data for being unreasonably fast. The most 
likely cause for this is GPS drift on very short trips, equipment malfunction, or the bikes being transported to 
another station by motor vehicle.

I created a new table called cleaned_combined_ride_share with 4 new columns called ride_duration_minutes, 
day_of_week, month, and distance_meters. I filtered out rides with a duration 0 minutes or less, rides with a 
duration less than 2 minutes that did not travel at least 50 meters or end at a different station, and rides 
where their straight line speed was over 8.5 m/s for classic bikes or over 11 m/s for electric bikes.

```sql
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
    ) --Created ride duration, month, day of week, distance, and average velocity columns
        
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
```

---

## Step 4: Analyze

### 4.1 Overall Statistics

```sql
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

| type  | avg_dist| std_dev_dist |
|-------|---------|--------------|
|casual | 2185.47 | 2019.73      |
|member | 2257.79 | 1986.41      |

| type | min_dist | q1_dist | q2_dist | q3_dist | max_dist |
|----- |----------|---------|---------|---------|----------|
|casual| 0.0      | 932.55  | 1650.06 | 2855.99 | 48370.88 |
|member| 0.0      | 954.65  | 1636.13 | 2949.42 | 48370.88 |

There appears to be minimal difference between the straight line distance that members and casuals travel.

```sql
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
```

| type | avg_time | std_dev_time |
|------|----------|--------------|
|casual| 19.17    | 38.01        |
|member| 12.19    | 21.6         |

| type | min_time | q1_time | q2_time | q3_time | max_time |
|------|----------|---------|---------|---------|----------|
|casual| 0.02     | 6.47    | 11.47   | 21.03   | 1439.97  |
|member| 0.02     | 5.12    | 8.68    | 14.7    | 1439.82  |

Member ride durations tend to be shorter and have much less variation than casual ride durations. Noteably, 
more than half of all member rides end before 10 minutes and more than 75% end before 15 minutes.

```sql
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
```

Velocity Results:
| Type | avg_velocity | std_dev_velocity |
|------|--------------|------------------|
|casual| 2.72         | 1.66             |
|member| 3.45         | 1.46             |

| Type | min_velocity | q1_velocity | q2_velocity | q3_velocity | max_velocity |
|------|--------------|-------------|-------------|-------------|--------------|
|casual| 0.0          | 1.59        | 2.78        | 3.85        | 11.0         |
|member| 0.0          | 2.61        | 3.45        | 4.38        | 11.0         |

Member ride velocities are also higher as a result of relatively similar distances and much shorter durations. 
This information would be much more interesting and useful if the bikes had an odometer that tracked the 
total distance covered.

```sql
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
```

```sql
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
```

Classic Bike Results:
| duration_category | pct_member | pct_casual |
|-------------------|------------|------------|
| 1) 0-45 min       | 98.0       | 84.86      |
| 2) 45 min - 3 hrs | 1.8        | 14.17      |
| 3) 3+ hrs         | 0.2        | 0.97       |

Electric Bike Results:
| duration_category | pct_member | pct_casual |
|-------------------|------------|------------|
| 1) 0-45 min       | 98.7       | 95.74      |
| 2) 45 min - 3 hrs | 1.22       | 4.22       |
| 3) 3+ hrs         | 0.08       | 0.04       |

Classic bikes have a free 45 minute grace period for members before they incur additional charges so it makes sense that members overwhelmingly end their rides before then. Similarly, casuals includes the day pass category which includes 3 hours before incurring additional charges so it makes sense for their rides to have a much larger percentage in that group. There is no similar free member period for electric bikes and the rates are similar between members and casuals, though casuals are more likely to have longer duration rides.

### 4.2 Seasonality Analysis

```sql
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
```

```sql
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
```

Results Casuals:
| month | ct     | pct_change_ct | avg_duration | pct_change_dur | avg_distance | pct_change_dist  |
|-------|--------|---------------|--------------|----------------|--------------|------------------|
| 1     | 24245  |               | 12.81        |                | 1615.75      |                  |
| 2     | 40448  | 66.83         | 13.95        | 8.9            | 1819.51      | 12.61            |
| 3     | 86024  | 112.68        | 16.63        | 19.21          | 1970.04      | 8.27             |
| 4     | 129026 | 49.99         | 16.4         | -1.38          | 2064.06      | 4.77             |
| 5     | 239914 | 85.94         | 19.39        | 18.23          | 2225.24      | 7.81             |
| 6     | 285582 | 19.04         | 21.33        | 10.01          | 2277.47      | 2.35             |
| 7     | 316138 | 10.7          | 20.9         | -2.02          | 2240.93      | -1.6             |
| 8     | 330755 | 4.62          | 21.22        | 1.53           | 2308.71      | 3.02             |
| 9     | 260061 | -21.37        | 19.14        | -9.8           | 2277.62      | -1.35            |
| 10    | 219670 | -15.53        | 17.64        | -7.84          | 2125.68      | -6.67            |
| 11    | 97106  | -55.79        | 14.7         | -16.67         | 1903.48      | -10.45           |
| 12    | 27481  | -71.7         | 12.68        | -13.74         | 1649.16      | -13.36           |

Results Members:
| month | ct     | pct_change_ct | avg_duration | pct_change_dur | avg_distance | pct_change_dist  |
|-------|--------|---------------|--------------|----------------|--------------|------------------|
| 1     | 111342 |               | 11.42        |                | 1838.72      |                  |
| 2     | 158345 | 42.21         | 10.67        | -6.57          | 1980.49      | 7.71             |
| 3     | 225628 | 42.49         | 11.22        | 5.15           | 2088.18      | 5.44             |
| 4     | 312164 | 38.35         | 11.39        | 1.52           | 2173.8       | 4.1              |
| 5     | 402640 | 28.98         | 12.32        | 8.17           | 2299.07      | 5.76             |
| 6     | 382627 | -4.97         | 12.73        | 3.33           | 2405.1       | 4.61             |
| 7     | 434775 | 13.63         | 13.02        | 2.28           | 2384.64      | -0.85            |
| 8     | 446895 | 2.79          | 12.96        | -0.46          | 2419.09      | 1.44             |
| 9     | 444273 | -0.59         | 12.51        | -3.47          | 2386.65      | -1.34            |
| 10    | 417535 | -6.02         | 12.01        | -4             | 2235.02      | -6.35            |
| 11    | 254555 | -39.03        | 11.53        | -4             | 2071.07      | -7.34            |
| 12    | 110669 | -56.52        | 11.55        | 0.17           | 1847.69      | -10.79           |

Both the number of member and casual rides show a distinct preference for summer months. However, the trend is much stronger for casual users with the winter averages dropping to less than 1/10 of their peak summer activity. Member activity during the winter only dropped to 1/4 of their peak summer activity.

The number of member rides also remains roughly consistent from May through October though there is a notable jump in activity during July. The number of casual rides stablizes between June and August. As compared to the members, casuals also show more rapid growth and drop off on either end of their stable usage period. 

Member ride duration maintained averages between 10.5 and 13.5 minutes. Casuals instead showed a very large variation in averages ranging from 12.7 to 21.3 minutes. This shows that casual rides are not only more common in the summer months but are also significantly longer while the member ride durations only slightly change.

Both members and casuals show similar distance trends as well with greater distance associated with warmer months. Generally, members averaged a slightly greater distance on their trips. During the winter months the difference was higher at around 200 meters and the gap shrank to less than 100 meters during the summer indicating that members show less variation as temperature changes.

### 4.3 Day of Week Analysis

```sql
--Determine the most popular days for members and casuals
--Identify any duration, distance, or velocity trends
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
```

| member_casual | day_of_week | ct     | avg_duration | avg_distance | avg_velocity  |
|---------------|-------------|--------|--------------|--------------|---------------|
| casual        | 1           | 352270 | 22.24        | 2260.24      | 2.49          |
| casual        | 2           | 240190 | 19.33        | 2123.66      | 2.71          |
| casual        | 3           | 230287 | 16.72        | 2107.1       | 2.93          |
| casual        | 4           | 232008 | 15.89        | 2096.73      | 2.98          |
| casual        | 5           | 261943 | 16.72        | 2131.32      | 2.94          |
| casual        | 6           | 316598 | 18.7         | 2166.93      | 2.75          |
| casual        | 7           | 423154 | 21.52        | 2297.03      | 2.52          |
| member        | 1           | 408689 | 13.39        | 2308.89      | 3.35          |
| member        | 2           | 520753 | 11.93        | 2211.68      | 3.47          |
| member        | 3           | 585663 | 11.75        | 2245.73      | 3.5           |
| member        | 4           | 587521 | 11.67        | 2247.31      | 3.51          |
| member        | 5           | 594163 | 11.73        | 2259.37      | 3.51          |
| member        | 6           | 541762 | 12.1         | 2211.93      | 3.45          |
| member        | 7           | 462897 | 13.33        | 2344.73      | 3.35          |

With Sunday-Saturday as 1-7, we can see that members and casuals follow opposite patterns. Casuals favor rides on the weekend with a particular focus on Saturdays. Member take more rides on weekdays with Wednesdays being the peak day. In both members and casuals, the average duration and distance peak on the weekend and show a mild elevation on Mondays and Fridays as compared to other weekdays. The member rides show a very slight decrease in the average velocity on the weekend whereas the weekend decrease is more pronounced in casual rides.

### 4.4 Time of Day Analysis
