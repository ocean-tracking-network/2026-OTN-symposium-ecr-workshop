# working with public otn data in r
# 2026 otn symposium ecr workshop

# ---- install packages (uncomment and run once if needed) ----
# install.packages(c("readr", "dplyr", "ggplot2", "lubridate", "maps", "plotly"))

# ---- setup check ----
library(readr)
library(dplyr)
library(ggplot2)
library(lubridate)
library(maps)
library(plotly)

# ---- 1. load the nsbs detection extract ----
# read_csv reads the zip files directly
nsbs_2021 <- read_csv("data/nsbs_matched_detections_2021.zip")
nsbs_2022 <- read_csv("data/nsbs_matched_detections_2022.zip")

# combine both years
detections <- bind_rows(nsbs_2021, nsbs_2022)

glimpse(detections)

# ---- 2. explore ----
# release rows mark where each animal was tagged
# they repeat in every yearly extract, so keep one per animal
releases <- detections %>%
  filter(toupper(receiver) == "RELEASE") %>%
  distinct(catalogNumber, .keep_all = TRUE)

# everything else is an actual detection
dets <- detections %>%
  filter(toupper(receiver) != "RELEASE")

# quick overview
tibble(
  animals_tagged   = nrow(releases),
  animals_detected = n_distinct(dets$catalogNumber),
  detections       = nrow(dets),
  projects         = n_distinct(dets$detectedBy),
  stations         = n_distinct(dets$station),
  first_detection  = min(dets$dateCollectedUTC),
  last_detection   = max(dets$dateCollectedUTC)
)

# whose receivers heard our animals?
count(dets, detectedBy, sort = TRUE)

# ---- 3. abacus plot ----
# version 1: default settings
ggplot(dets, aes(x = dateCollectedUTC, y = catalogNumber, colour = detectedBy)) +
  geom_point() +
  labs(x = "date", y = "animal", colour = "receiver project") +
  theme_minimal()

# fix 1: sort animals by first detection
animal_order <- dets %>%
  group_by(catalogNumber) %>%
  summarise(first_det = min(dateCollectedUTC)) %>%
  arrange(first_det) %>%
  pull(catalogNumber)

dets <- dets %>%
  mutate(catalogNumber = factor(catalogNumber, levels = rev(animal_order)))

# fix 2: colour the top 5 receiver projects, grey for the rest
# top projects are picked automatically, so this works on your own data too
top_projects <- count(dets, detectedBy, sort = TRUE) %>%
  slice_head(n = 5) %>%
  pull(detectedBy)

dets <- dets %>%
  mutate(project_group = if_else(detectedBy %in% top_projects, detectedBy, "other"))

# keep the legend in order of detections, with "other" last
dets <- dets %>%
  mutate(project_group = factor(project_group, levels = c(top_projects, "other")))

project_colours <- setNames(
  c(hcl.colors(length(top_projects), "Dark 3"), "grey70"),
  c(top_projects, "other")
)

# fix 3: one mark per animal per day, so busy animals don't become solid blocks
daily <- dets %>%
  mutate(day = as_date(dateCollectedUTC)) %>%
  distinct(catalogNumber, day, project_group)

# version 2: sorted, coloured, one mark per day
# the label function drops the project code at the start of each id
ggplot(daily, aes(x = day, y = catalogNumber, colour = project_group)) +
  geom_point(shape = 15, size = 1.2) +
  scale_colour_manual(values = project_colours) +
  scale_y_discrete(labels = function(x) sub("^[^-]+-", "", x)) +
  labs(title = "when was each animal detected?",
       subtitle = "one mark per animal per day, sorted by first detection",
       x = "date", y = "animal", colour = "receiver project") +
  theme_minimal() +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(),
        axis.text.y = element_text(size = 7))

# ---- 4. detections over time ----
# animals detected per month (less skewed than raw detection counts)
monthly <- dets %>%
  mutate(month = floor_date(dateCollectedUTC, "month")) %>%
  group_by(month) %>%
  summarise(detections = n(),
            animals    = n_distinct(catalogNumber))

ggplot(monthly, aes(x = month, y = animals)) +
  geom_col(fill = "steelblue") +
  labs(title = "animals detected per month",
       x = "month", y = "animals") +
  theme_minimal()

# ---- 5. map of detections ----
# one point per station, sized by number of animals heard there
station_summary <- dets %>%
  group_by(detectedBy, station, decimalLatitude, decimalLongitude) %>%
  summarise(detections = n(),
            animals    = n_distinct(catalogNumber),
            .groups = "drop")

# map extent with some padding
lon_range <- range(c(dets$decimalLongitude, releases$decimalLongitude)) + c(-2, 2)
lat_range <- range(c(dets$decimalLatitude,  releases$decimalLatitude))  + c(-2, 2)

# static map: blue = detection stations, orange = release sites
# "text" is only used by the zoomable version below, ggplot will warn about it, that's fine
detection_map <- ggplot() +
  borders("world", fill = "grey90", colour = "grey60") +
  geom_point(data = station_summary,
             aes(x = decimalLongitude, y = decimalLatitude, size = animals, text = station),
             shape = 21, fill = "steelblue", colour = "white", alpha = 0.8) +
  geom_point(data = releases,
             aes(x = decimalLongitude, y = decimalLatitude),
             shape = 24, fill = "darkorange", colour = "white", size = 3) +
  scale_size(range = c(1.5, 6)) +
  coord_quickmap(xlim = lon_range, ylim = lat_range) +
  labs(title = "where were our animals detected?",
       subtitle = "blue = detection stations, orange = release sites",
       x = "longitude", y = "latitude", size = "animals") +
  theme_minimal()

detection_map

# zoomable version: hover to see the station name
ggplotly(detection_map, tooltip = c("text", "size"))

# ---- 6. public data: receiver stations from otn geoserver ----
# receiver metadata is public, and a geoserver request is just a url
# cql_filter keeps only receivers inside our map area
# maxFeatures raises the default limit of 50 records
region_filter <- paste0(
  "stn_long BETWEEN ", lon_range[1], " AND ", lon_range[2],
  " AND stn_lat BETWEEN ", lat_range[1], " AND ", lat_range[2]
)

stations_url <- paste0(
  "https://members.oceantrack.org/geoserver/otn/ows?",
  "service=WFS&version=1.0.0&request=GetFeature",
  "&typeName=otn:stations_receivers",
  "&outputFormat=csv",
  "&maxFeatures=50000",
  "&cql_filter=", URLencode(region_filter)
)

stations <- read_csv(stations_url)

# check we got everything (should be well under 50000)
nrow(stations)

# backup if geoserver is slow or down
# stations <- read_csv("data/otn_stations_backup.csv")

# keep receivers deployed at some point during our study period
study_start <- as_date(min(dets$dateCollectedUTC))
study_end   <- as_date(max(dets$dateCollectedUTC))

stations_deployed <- stations %>%
  mutate(deploy_date   = as_date(deploy_date),
         recovery_date = as_date(recovery_date)) %>%
  filter(!is.na(deploy_date),
         deploy_date <= study_end,
         is.na(recovery_date) | recovery_date >= study_start)

# ---- 7. augmented map: detections within the receiver network ----
# grey = receivers deployed during the study period, blue = where animals were heard
# "text" sets the hover labels for the interactive version, ggplot will warn about it, that's fine
network_map <- ggplot() +
  borders("world", fill = "grey95", colour = "grey70") +
  geom_point(data = stations_deployed,
             aes(x = stn_long, y = stn_lat),
             colour = "grey60", size = 0.6, alpha = 0.4) +
  geom_point(data = station_summary,
             aes(x = decimalLongitude, y = decimalLatitude, size = animals,
                 text = paste0("station: ", station,
                               "<br>project: ", detectedBy,
                               "<br>animals: ", animals,
                               "<br>detections: ", detections)),
             shape = 21, fill = "steelblue", colour = "white", alpha = 0.9) +
  geom_point(data = releases,
             aes(x = decimalLongitude, y = decimalLatitude,
                 text = paste0("release: ", catalogNumber)),
             shape = 24, fill = "darkorange", colour = "white", size = 3) +
  scale_size(range = c(1.5, 6)) +
  coord_quickmap(xlim = lon_range, ylim = lat_range) +
  labs(title = "our detections within the otn receiver network",
       subtitle = "grey = receivers deployed during the study period, blue = detections, orange = release sites",
       x = "longitude", y = "latitude", size = "animals") +
  theme_minimal()

network_map

# interactive version: zoom in and hover over points
ggplotly(network_map, tooltip = "text")

# ---- 8. tips and tricks ----

# detection extracts
# - extracts come as one file per year, combine them with bind_rows()
# - release rows repeat in every yearly extract, keep one per animal with distinct()
# - extracts are updated after every data push (about every 4 months), so re-download for new matches
# - since june 2025 column names are camelCase, older tutorials may use the old names
# - open extracts in r, not excel, excel can mangle times with fractional seconds
# - use the citation column to credit the receiver owners who heard your animals

# plotting
# - count animals, not detections, so one animal sitting near a receiver doesn't skew your plots
# - in abacus plots, one mark per animal per day reads better than every detection
# - sort rows by something meaningful, like first detection
# - colour only what matters (top 5 or so) and put the rest in grey
# - use light grey for context layers so your main data stands out
# - ggplotly() turns most ggplots interactive in one line

# public data
# - geoserver returns 50 records by default, raise it with maxFeatures
# - if nrow() equals your maxFeatures, your download got cut off
# - filter on the server (cql_filter) so you only download what you need
# - if you pull data from erddap, its csvs have a units row under the header, skip it when reading
# - save a local copy of anything you download in case the server is down

# ---- links ----
# discovery portal: https://members.oceantrack.org/data/discovery/bypublic.htm
# geoserver:        https://members.oceantrack.org/geoserver/web/
# erddap:           https://members.oceantrack.org/erddap/index.html
# obis / ipt:       https://members.oceantrack.org/ipt/
# questions:        otndc@dal.ca