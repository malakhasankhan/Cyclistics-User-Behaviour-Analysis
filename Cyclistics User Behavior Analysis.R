

# ============================================
# Cyclistic's User Behavior R Analysis 
# MALAK HASAN KHAN 
# Dated: 28/4/2025
# ============================================


# --------------------------------------------
# 0. Setup: Load the Cleaned Dataset
# --------------------------------------------

all_trips_2024_202504241413 <- read.csv("D:/Data Analytics/Projects/Google Case Study 1 - Cyclists/2024 Annual Data/all_trips_2024_202504241413.csv")
View(all_trips_2024_202504241413)

# Create a working copy of the dataset
all_trips_2024<- all_trips_2024_202504241413

# Libraries needed
library(tidyverse)
library(scales)

# Quick structural check
summary(all_trips_2024)
str(all_trips_2024)
head(all_trips_2024)

#  Note: The dataset was fully cleaned in SQL.
#  No additional cleaning needed here — we directly dive into visualization and insights.

#  --------------------------------------------
#  1. Trip Duration Variations: Casual vs Members
#  --------------------------------------------
all_trips_2024 %>% 
  select(member_casual, trip_duration) %>% 
  ggplot(aes(x=member_casual, y = trip_duration))+
  geom_boxplot(fill = c("#0073C2FF", "#EFC000FF"))+
  scale_y_continuous(limits = c(0,60))+
  labs(title="Trip Duration Variations: Casual VS Members", 
       y='Trip Duration', 
       x= 'Rider Type')+
  theme_minimal()
  
#   Insights:
# - Casual riders have higher median trip durations.
# - Greater variability among casuals, suggesting diverse use cases.
# - Members have shorter, more consistent ride durations — likely functional trips.

#  Converting Date_time column into proper format for analysis. 
all_trips_2024$started_at<- ymd_hms(all_trips_2024$started_at)

# --------------------------------------------
# 2. Total Trips by Month
# --------------------------------------------
monthly_counts <- all_trips_2024 %>%
  count(member_casual, ride_month) %>%
  mutate(ride_month = factor(ride_month, 
                             levels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")))

# Ordering the Months as per the Calendar
View(monthly_counts)
monthly_counts <- monthly_counts %>%
  complete(member_casual, ride_month, fill = list(n = 0))  # Fills missing months with 0 trips

#Plot monthly trip counts
ggplot(monthly_counts, aes(x=ride_month, y=n,group=member_casual, color=member_casual))+
         geom_line()+
  labs(title = "Total Trips by Month (2024)",
       x = "Month",
       y = "Total Trips",
       color = "Rider Type") +
  guides(x=guide_axis(angle=90))+
  scale_y_continuous(labels=comma)

# - Both rider types peak in October.
# - For casual riders, this aligns with pleasant weather.
# - For members, this could coincide with university sessions restarting.

# --------------------------------------------
# 3. Average Trip Duration Over the Year
# --------------------------------------------

all_trips_2024 %>% 
  group_by(member_casual, ride_month) %>% 
  summarise(avg_trip_duration = mean(trip_duration)) %>% 
  mutate(ride_month = factor(ride_month, 
                             levels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"))) %>% 
  ggplot(aes(x=ride_month, y =avg_trip_duration, group=member_casual, color=member_casual))+
  geom_line()+
  labs(title = "Average Trip Duration by Month (2024)",
       x = "Month",
       y = "Average Trip Duration",
       color = "Rider Type")+
  guides(x=guide_axis(angle=90))+
  theme_minimal()

# - Casual riders consistently have longer trips across all months.

# --------------------------------------------
# 4. Weekly Ride Distribution: Casual vs Members
# --------------------------------------------

all_trips_2024 %>% 
  count(member_casual, day_of_week) %>% 
  mutate(day_of_week = factor(day_of_week, levels = c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"))) %>% 
  ggplot(aes(x=day_of_week, y =n,group=member_casual, fill=member_casual))+
  geom_bar(stat = "identity", position = "dodge")+
  guides(x=guide_axis(angle=90))+
  scale_y_continuous(labels=comma)+
  labs(title='Weekly Ride Distribution',
       x="Day of the Week",
       y= "Total Rides", 
       fill="Rider Type")
  

# - Casual riders peak on Saturdays — classic leisure behavior.
# - Members peak midweek (Wednesday) — aligned with work commutes.

# --------------------------------------------
# 5. Hourly Ride Patterns
# --------------------------------------------
#According to my hypothesis, for members, since they are using bikes more functionally, there will be two peaks in the day, one early in the morning and other later in the afternoon. 
#For casual riders, it should be more erratic and start later in the day. 

all_trips_2024 %>% 
  mutate(ride_hour=hour(started_at)) %>% 
  count(member_casual,ride_hour) %>% 
  ggplot(aes(x=ride_hour, y=n, color=member_casual,group=member_casual )) +
  geom_line()+
  scale_x_continuous(breaks= seq(0,23,by=2))+
  scale_y_continuous(labels=comma)+
  guides(x=guide_axis(angle=90))+
  labs(title = "Hourly Ride Distribution by Rider Type",
       x="Hour of Day",
       y="Total Rides",
       color="Rider Type")

# - Members show two strong commute peaks: 8 AM and 5 PM.
# - Casual riders have a more gradual midday peak — aligned with leisure riding.


# --------------------------------------------
# End of Analysis 
# --------------------------------------------


## Junk Analysis
casual_routes<-all_trips_2024 %>%
  filter(
    !is.na(start_station_name), 
    !is.na(end_station_name),
    str_trim(start_station_name) != "",
    str_trim(end_station_name) != "",
    !is.na(start_lat), !is.na(start_lng),
    !is.na(end_lat), !is.na(end_lng)
  ) %>%
  group_by(member_casual, start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng) %>%
  summarise(trip_count = n(), .groups = "drop") %>%
  arrange(desc(trip_count)) %>% 
  slice_max(trip_count,n=10)


  
  
  
  
  

