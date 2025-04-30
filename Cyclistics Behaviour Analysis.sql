/*
   =====================================
   CYCLISTICS USER BEHAVIOUR ANALYSIS in SQL 
   AUTHOR: MALAK HASAN KHAN 
   DATE: 28/4/2025
   =====================================
 */
-- ===============================
-- 1. Data Cleaning: Setting the Foundation
-- ===============================

-- Let's begin by making sure the basics are in place.

-- Are there any missing or blank values in our critical columns?
SELECT 
 Count(*)
 
 FROM 
 "202401_divvy_tripdata"
 
 WHERE 
 ride_id IS NULL or TRIM(ride_id)=''
 OR started_at iS NULL OR TRIM(started_at) = ''
 OR ended_at IS NULL OR TRIM(ended_at) = ''
 OR member_casual IS NULL OR TRIM(member_casual) = ''
 
-- Surprisingly, no missing values were found! 
-- This gives us confidence that the data integrity is solid — at least structurally.
 
 -- 02 - Checking for Logical Inconsistencies 
 -- a) Could there be rides where the bike "ended" before it even "started"? Let's check.
 
 SELECT *
 FROM
 "202401_divvy_tripdata"
 
 WHERE 
 julianday(ended_at) <= julianday(started_at)
 
-- Found some suspicious rides where ended_at is less than or equal to started_at. 
-- These are clearly errors and could skew our analysis.
 
 -- We are going to delete these values 
DELETE FROM  "202412_divvy_tripdata"
WHERE julianday(ended_at) <= julianday(started_at);

-- All the values are now deleted for all the tables.

-- b) We need to standardize the table by checking if there are any inconsistencies in the member_casual column values. 
SELECT DISTINCT member_casual 
FROM 
"202412_divvy_tripdata"

-- member_casual labels are clean and standardized.

-- c) Let's also quickly check for duplicate ride IDs — we don't want to count the same trip twice.
SELECT ride_id, 
COUNT(*)
FROM 
"202412_divvy_tripdata"
GROUP BY
ride_Id
Having COUNT(*) > 1
--  No duplicate ride_ids found

-- d) Checking for Rows where start or end station name is NULL 
 SELECT 
 start_station_name, 
 end_station_name
 FROM 
 "202401_divvy_tripdata"
WHERE 
TRIM(start_station_name) = ''
OR TRIM(end_station_name) = ''
 
-- Hmm. Some blank station names exist.
-- Since our core analysis doesn't depend directly on station names, we’ll keep these rows for now.

-- With this we conclude, the cleaning phase of the data. 

-- =====================================================================
-- 2. BIAS CHECK: Analyzing Data for any Skewdness
-- =====================================================================

-- Ensuring no overwhelming imbalance between members and casual riders.
-- a) User type Biasness - Is there too much data on one side to skew the result s

SELECT 
member_casual, 
COUNT(*)

FROM 
"202412_divvy_tripdata"

GROUP BY member_casual 

-- There is a 80-20% split in the distribution of annual members and classic riders. Consequently, we will always keep the two separate when doing comparative analysis. 

-- =======================================================================
-- 3. PROCESSING DATA FOR ANALYSIS
-- =======================================================================

-- NOTE: Data Processsing would have been easier if I had joined all the tables in the first step. Hence, if you find any month specific queries, they have been applied to all the months. 

-- Adding Column Trip Duration - Calculating how long trips lasted (in minutes)

ALTER TABLE "202412_divvy_tripdata" ADD COLUMN trip_duration REAL;
UPDATE "202412_divvy_tripdata"
SET trip_duration = (JULIANDAY (ended_at)-JULIANDAY(started_at)) * 24 * 60;
SELECT * 
FROM "202412_divvy_tripdata"
LIMIT 10 

-- All of the tables have been updated to add the trip_duration (in minutes) column 

-- For efficiency we are going to combine all the monthly tables into one unified table. 
-- In order to mantain the ability to do month wise analysis, we will add a column for the month.

CREATE TABLE all_trips_2024 AS 
SELECT *, 'Jan' AS ride_month FROM "202401_divvy_tripdata"
UNION ALL 
SELECT *, 'Feb' AS ride_month FROM "202402_divvy_tripdata"
UNION ALL 
SELECT *, 'Mar' AS ride_month FROM "202403_divvy_tripdata"
UNION ALL 
SELECT *, 'Apr' AS ride_month FROM "202404_divvy_tripdata"
UNION ALL 
SELECT *, 'May' AS ride_month FROM "202405_divvy_tripdata"
UNION ALL 
SELECT *, 'Jun' AS ride_month FROM "202406_divvy_tripdata"
UNION ALL 
SELECT *, 'Jul' AS ride_month FROM "202407_divvy_tripdata"
UNION ALL 
SELECT *, 'Aug' AS ride_month FROM "202408_divvy_tripdata"
UNION ALL 
SELECT *, 'Sep' AS ride_month FROM "202409_divvy_tripdata"
UNION ALL 
SELECT *, 'Oct' AS ride_month FROM "202410_divvy_tripdata"
UNION ALL 
SELECT *, 'Nov' AS ride_month FROM "202411_divvy_tripdata"
UNION ALL 
SELECT *, 'Dec' AS ride_month FROM "202412_divvy_tripdata"

-- Ride month is now added. I will use the all_trips_2024 table for further analysis

-- Adding day_of_week Column for identifying trends on specific days. 

ALTER TABLE all_trips_2024 ADD COLUMN day_of_week TEXT  
UPDATE all_trips_2024
SET day_of_week = CASE strftime('%w', started_at)
WHEN '0' THEN 'Sunday'
WHEN '1' THEN 'Monday'
WHEN '2' THEN 'Tuesday'
WHEN '3' THEN 'Wednesday'
WHEN '4' THEN 'Thursday'
WHEN '5' THEN 'Friday'
WHEN '6' THEN "Saturday"
END

-- Checking if the query ran successfully. 
SELECT * 
FROM all_trips_2024
LIMIT 10 

-- Each ride now has an associated weekday name. 

-- ======================================================================
-- 4. Exploratory Analysis: Finding Patterns
-- ======================================================================

-- 4.1 Average Trip Duration By Month: Casual Riders 
SELECT 
ride_month, 
member_casual,
AVG(trip_duration)

FROM all_trips_2024

WHERE member_casual = 'casual'

GROUP BY 
ride_month, 
member_casual

ORDER BY started_at ASC

-- For casual riders, the trip duration peaks in May, June and July. 

-- 4.2 Average Trip Duration BY Month: Annual Members
SELECT 
ride_month, 
member_casual,
AVG(trip_duration)
FROM all_trips_2024
WHERE member_casual = 'member'
GROUP BY 
ride_month, 
member_casual
ORDER BY started_at ASC

-- Interestingly, members ride shorter trips with stable trip durations throughout the year. 

-- Here is my hypothesis:
-- 1) Members ride for function (Commuting)
-- 2) Casuals ride for Pleasure 

-- We are going to explore this hypothesis from multiple angles. 

-- 4.3 Ride Patterns by Day of Week : Member Riders 

SELECT 
ride_month, 
day_of_week, 
COUNT(*)
FROM all_trips_2024
WHERE member_casual = 'member'
GROUP BY 
ride_month, 
day_of_week
ORDER BY  CASE ride_month
    WHEN 'Jan' THEN 1
    WHEN 'Feb' THEN 2
    WHEN 'Mar' THEN 3
    WHEN 'Apr' THEN 4
    WHEN 'May' THEN 5
    WHEN 'Jun' THEN 6
    WHEN 'Jul' THEN 7
    WHEN 'Aug' THEN 8
    WHEN 'Sep' THEN 9
    WHEN 'Oct' THEN 10
    WHEN 'Nov' THEN 11
    WHEN 'Dec' THEN 12
  END,
CASE day_of_week
    WHEN 'Sunday' THEN 1
    WHEN 'Monday' THEN 2
    WHEN 'Tuesday' THEN 3
    WHEN 'Wednesday' THEN 4
    WHEN 'Thursday' THEN 5
    WHEN 'Friday' THEN 6
    WHEN 'Saturday' THEN 7
  END

-- Members rides peak midweek on Wednesdays and fall over the weekend.  
  
-- 4.4 Ride Patterns by Day of Week: Casual Riders
 SELECT 
ride_month, 
day_of_week, 
COUNT(*)
FROM all_trips_2024
WHERE member_casual = 'casual'
GROUP BY 
ride_month, 
day_of_week
ORDER BY  CASE ride_month
    WHEN 'Jan' THEN 1
    WHEN 'Feb' THEN 2
    WHEN 'Mar' THEN 3
    WHEN 'Apr' THEN 4
    WHEN 'May' THEN 5
    WHEN 'Jun' THEN 6
    WHEN 'Jul' THEN 7
    WHEN 'Aug' THEN 8
    WHEN 'Sep' THEN 9
    WHEN 'Oct' THEN 10
    WHEN 'Nov' THEN 11
    WHEN 'Dec' THEN 12
  END,
CASE day_of_week
    WHEN 'Sunday' THEN 1
    WHEN 'Monday' THEN 2
    WHEN 'Tuesday' THEN 3
    WHEN 'Wednesday' THEN 4
    WHEN 'Thursday' THEN 5
    WHEN 'Friday' THEN 6
    WHEN 'Saturday' THEN 7
  END
  

-- Rides for Casual riders peak on Weekends esp Saturday. 
 
-- Our hypothesis follows through. 
-- You would expect offices and educational institutes closed on weekends and we expect lower trips.
-- For sightseeing and pleasure, people generally tend to travel over the weekend.
  
-- 4.5 To expand on this analysis, let's do a weekend/weekday analysis to make sure. 
SELECT 
  ride_month,
CASE 
  WHEN day_of_week = "Monday" THEN 'Weekday'
  WHEN day_of_week = "Tuesday" THEN 'Weekday'
  WHEN day_of_week = "Wednesday" THEN 'Weekday'
  WHEN day_of_week = "Thursday" THEN 'Weekday'
  WHEN day_of_week = "Friday" THEN 'Weekday'
ElSE 'Weekend'
END AS weekday_weekend, 
Count(*)
FROM all_trips_2024
Where member_casual = 'member'
GROUP BY 
ride_month, 
weekday_weekend
ORDER BY started_at ASC
 
-- Weekday to Weekend ratio is higher for annual members. 

-- 4.6 Weekend/Weekday analysis for Casuals 
 
 SELECT 
  ride_month,
 CASE 
  WHEN day_of_week = "Monday" THEN 'Weekday'
  WHEN day_of_week = "Tuesday" THEN 'Weekday'
  WHEN day_of_week = "Wednesday" THEN 'Weekday'
  WHEN day_of_week = "Thursday" THEN 'Weekday'
  WHEN day_of_week = "Friday" THEN 'Weekday'
  ElSE 'Weekend'
 END AS weekday_weekend, 
 Count(*)
 FROM all_trips_2024
 Where member_casual = 'casual'
 GROUP BY 
 ride_month, 
 weekday_weekend
 ORDER BY started_at ASC
 
 -- Weekday to Weekend ration is smaller for casual riders. 
 -- Majority of Casual rides take place on weekends. 

 
-- 4.7 Ride Hour Analysis: Annual Members
 SELECT 
 strftime('%H',started_at) AS ride_hour, 
 COUNT(*)
 FROM all_trips_2024
 WHERE member_casual = 'member'
 GROUP BY ride_hour
 
 -- For members, the highest rides are recorded at 7,8 AM in the morning and 4, 5 and 6 PM in the evening. These times coincide with normal working hours. 
 
 -- 4.8 Ride Hour Analaysis: Casual Members
 SELECT 
 strftime('%H',started_at) AS ride_hour, 
 COUNT(*)
 FROM all_trips_2024
 WHERE member_casual = 'casual'
 GROUP BY ride_hour
 
 -- Casual rides tend to peak during midday leisure hours. There is only one peak for Casual riders.   
 
 -- 4.9 Round Trip vs One-Way Trip Analysis : Annual Members
 
 SELECT COUNT(*) AS total, 
 SUM(CASE WHEN start_station_name = end_station_name THEN 1 ELSE 0 END) AS roundtrips, 
 SUM(CASE WHEN start_station_name != end_station_name THEN 1 ELSE 0 END) AS one_way
 FROM all_trips_2024
 WHERE member_casual = 'member'
 GROUP BY member_casual
 
-- For annual members the ratio of roundtrips to one way trips is 376,601 to 3,331,847
 
-- 4.10 Round Trip vs One-Way Trip Analysis: Casual Riders 
 SELECT COUNT(*) AS total, 
 SUM(CASE WHEN start_station_name = end_station_name THEN 1 ELSE 0 END) AS roundtrips, 
 SUM(CASE WHEN start_station_name != end_station_name THEN 1 ELSE 0 END) AS one_way
 FROM all_trips_2024
 WHERE member_casual = 'casual'
 GROUP BY member_casual
 
-- For Casual members, the ratio is 380,777 to 1,770,620. IN terms of percentage, the roundtrips %age is still higher than for annual members, but still the increase isn't signifcant. 
-- One Way trips are dominant for both.
 
-- Top 10 Start-End Route: Annual Members
 SELECT 
 start_station_name, 
 end_station_name, 
 COUNT(*)
 FROM all_trips_2024
 WHERE member_casual = 'member'
 AND TRIM(start_station_name) != ''
 AND TRIM(end_station_name) != ''
 GROUP BY 
 start_station_name, 
 end_station_name
 ORDER BY COUNT(*) DESC
 LIMIT 10
 
-- Some Annual members travel between same stations. 
 
-- Top 10 Start-End Routes: Casual Riders 
 SELECT 
 start_station_name, 
 end_station_name, 
 COUNT(*)
 FROM all_trips_2024
 WHERE member_casual = 'casual'
 AND TRIM(start_station_name) != ''
 AND TRIM(end_station_name) != ''
 GROUP BY 
 start_station_name, 
 end_station_name
 ORDER BY COUNT(*) DESC
 LIMIT 10
 
 -- Casuals dont tend to follow same routes. Most locations seem touristy,
 
--  With this, we come to the end of our Analysis. 
 
--  ==============================================================
--  Takeaways
--  ==============================================================
 -- Casual riders are tourists 
 -- Casual riders ride around not for travelling but for taking in the sights 
 -- They ride for pleasure
 -- Summers are preferred for Rides for both type of travellers. 
 -- Weekends have higher rides for casual riders than for annual riders
 --
 
 -- ================================================================
 -- Recommendations
 -- ================================================================
 -- Create summer Bundles for casual riders. 
 -- Market on tourist booking sites like hotel booking or trip booking sites. 
 -- Offer unlimited rides on Tourist heavy locations for Annual Mambers.  
 