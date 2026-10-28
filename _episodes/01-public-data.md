---
title: Working with Public OTN Data in R
teaching: 60
exercises: 0
questions:
  - "What data does OTN make publicly available?"
  - "How do I load an OTN detection extract into R?"
  - "How do I make clear plots of detection data?"
  - "How can I add public OTN data to my own plots?"
---

## Intro to OTN

The Ocean Tracking Network (OTN) supports global telemetry research by providing training, equipment, and data infrastructure to a large network of partners.

OTN cross-references detection data from receivers across the network with tag records from all projects. This means an animal tagged by one project can be detected by receivers owned by many other projects. The results are sent to researchers as detection extracts after each data push, which happens about every 4 months.

Learn more about OTN and our partners here: [https://members.oceantrack.org/](https://members.oceantrack.org/).
Please contact **OTNDC@DAL.CA** if you have questions or are interested in connecting with your regional network.

## Public and Private Data

OTN provides two kinds of data products:

- **Detection extracts** are sent to project members through their project's private repository. They contain the detections matched to a project's tags or receivers.
- **Public data** is available to anyone without a login, under a CC-BY license. This includes receiver metadata, tagging metadata for published projects, and published detections.

Public data can be accessed through several endpoints:

- **Discovery Portal**: a searchable catalogue of OTN projects and datasets. [https://members.oceantrack.org/data/discovery/bypublic.htm](https://members.oceantrack.org/data/discovery/bypublic.htm)
- **GeoServer**: spatial layers such as receiver stations and tag releases. [https://members.oceantrack.org/geoserver/web/](https://members.oceantrack.org/geoserver/web/)
- **ERDDAP**: tabular and time series datasets, including public detections. [https://members.oceantrack.org/erddap/index.html](https://members.oceantrack.org/erddap/index.html)
- **OBIS**: species occurrence records published through OTN's IPT. [https://members.oceantrack.org/ipt/](https://members.oceantrack.org/ipt/)

In this lesson we will work with a detection extract from the NSBS (blue shark) project, make plots from it, and then add public receiver data from GeoServer.

## Getting Started

Please follow the instructions in the **"Setup"** tab along the top menu to install all required software, packages and data files. The full script for this lesson is available in the code folder as `01-public-data.R`.

**NOTE:** this workshop uses OTN's 2025 Detection Extract Format. In June 2025 most column names changed to camelCase, so older tutorials may use different column names.

## Setup

~~~
# ---- install packages (uncomment and run once if needed) ----
# install.packages(c("readr", "dplyr", "ggplot2", "lubridate", "maps", "plotly"))

# ---- setup check ----
library(readr)
library(dplyr)
library(ggplot2)
library(lubridate)
library(maps)
library(plotly)
~~~
{: .language-r}

## Load the Detection Extract

Detection extracts come as one file per year. We will load two years of NSBS data and combine them.

~~~
# ---- 1. load the nsbs detection extract ----
# read_csv reads the zip files directly
nsbs_2021 <- read_csv("data/nsbs_matched_detections_2021.zip")
nsbs_2022 <- read_csv("data/nsbs_matched_detections_2022.zip")

# combine both years
detections <- bind_rows(nsbs_2021, nsbs_2022)

glimpse(detections)
~~~
{: .language-r}

## Explore the Data

Each extract includes release rows, which mark where each animal was tagged. These have `release` in the receiver column. Release rows repeat in every yearly extract, so we keep one per animal.

~~~
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
~~~
{: .language-r}

## Abacus Plot

An abacus plot shows when each animal was detected. We start with the default plot, then make three changes to make it easier to read:

1. Sort animals by their first detection.
2. Colour only the top 5 receiver projects and put the rest in grey.
3. Show one mark per animal per day instead of every detection.

~~~
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
~~~
{: .language-r}

## Detections Over Time

Counting animals instead of detections keeps one animal that stays near a receiver from skewing the plot.

~~~
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
~~~
{: .language-r}

## Map of Detections

We summarise detections to one point per station, sized by the number of animals detected there. Release sites are shown as triangles. The `ggplotly()` function turns the map into an interactive version you can zoom and hover over.

~~~
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
~~~
{: .language-r}

## Public Data: Receiver Stations from GeoServer

Receiver metadata is public and available through OTN's GeoServer. A GeoServer request is a URL that can be read directly into R. We use a filter so we only download receivers inside our map area, then keep the receivers that were deployed at some point during our study period.

~~~
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
~~~
{: .language-r}

## Detections Within the Receiver Network

Now we add the public receiver stations to our detection map. Receivers are shown in light grey so the detections stand out.

Note that a receiver counts as deployed if its deployment overlaps any part of the study period. This does not mean it was working the whole time.

~~~
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
~~~
{: .language-r}

## Tips and Tricks

#### Detection extracts

- Extracts come as one file per year. Combine them with `bind_rows()`.
- Release rows repeat in every yearly extract. Keep one per animal with `distinct()`.
- Extracts are updated after every data push, so download them again to get new matches.
- Open extracts in R, not Excel. Excel can change times that have fractional seconds.
- Use the citation column to credit the receiver owners who detected your animals.

#### Plotting

- Count animals, not detections, so one animal near a receiver does not skew your plots.
- In abacus plots, one mark per animal per day is easier to read than every detection.
- Sort rows by something meaningful, like first detection.
- Colour only what matters and put the rest in grey.
- Use light grey for background layers so your main data stands out.
- `ggplotly()` turns most ggplots into interactive plots in one line.

#### Public data

- GeoServer returns 50 records by default. Raise this with `maxFeatures`.
- If `nrow()` equals your `maxFeatures`, your download was cut off.
- Filter on the server with `cql_filter` so you only download what you need.
- ERDDAP CSV files have a units row under the header. Skip it when reading.
- Save a local copy of anything you download in case the server is down.

## Links

- Discovery Portal: [https://members.oceantrack.org/data/discovery/bypublic.htm](https://members.oceantrack.org/data/discovery/bypublic.htm)
- GeoServer: [https://members.oceantrack.org/geoserver/web/](https://members.oceantrack.org/geoserver/web/)
- ERDDAP: [https://members.oceantrack.org/erddap/index.html](https://members.oceantrack.org/erddap/index.html)
- OBIS / IPT: [https://members.oceantrack.org/ipt/](https://members.oceantrack.org/ipt/)
- Detection extract documentation: [https://members.oceantrack.org/data/otn-detection-extract-documentation-matched-to-animals](https://members.oceantrack.org/data/otn-detection-extract-documentation-matched-to-animals)
- Questions: **OTNDC@DAL.CA**
