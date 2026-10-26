```python
# 6 files were too large to uplaod directly to BigQuery (>100 MB) and needed to be chunked
    
# import package and alias
import pandas as pd

# convert the csv files into data frames (replace with your pathway if cloning)
df_2025_06 = pd.read_csv(r'data/raw_data/2025_06_Cyclistic_Data.csv')
df_2025_07 = pd.read_csv(r'data/raw_data/2025_07_Cyclistic_Data.csv')
df_2025_08 = pd.read_csv(r'data/raw_data/2025_08_Cyclistic_Data.csv')
df_2025_09 = pd.read_csv(r'data/raw_data/2025_09_Cyclistic_Data.csv')
df_2025_10 = pd.read_csv(r'data/raw_data/2025_10_Cyclistic_Data.csv')
df_2026_05 = pd.read_csv(r'data/raw_data/2026_05_Cyclistic_Data.csv')

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
