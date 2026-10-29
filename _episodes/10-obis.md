---
title: "Supplemental: Accessing OTN Data via OBIS"
teaching: 15
exercises: 15
questions:
- "What does OBIS hold for the Ocean Tracking Network?"
- "How do I query OTN records by node, dataset, or species?"
- "How can I bring OTN occurrence data into R or Python for mapping?"
objectives:
- "Recognize what OTN contributes to OBIS (occurrence-focused)."
- "Filter OBIS by OTN node, dataset, taxon, region, and time."
- "Load OTN records into R or Python and make a quick map."
keypoints:
- "OBIS hosts species occurrence records."
- "OTN is an OBIS node; UUID: 68f83ea7-69a7-44fd-be77-3c3afd6f3cf8."
- "Use robis (R) or pyobis (Python) for programmatic queries."
- "Keep queries lean with fields, geometry, time window, and paging."
---

## What is OBIS and how does OTN fit in?

* OBIS (Ocean Biodiversity Information System) is the global hub for marine species
  occurrence data.
* The Ocean Tracking Network (OTN) is one of OBIS’s regional nodes.
  OTN contributes tagging and tracking metadata summarized as occurrence records
  (for example, tag releases and detection events).
* To focus only on OTN-contributed data, use the OTN node UUID:

~~~
68f83ea7-69a7-44fd-be77-3c3afd6f3cf8
~~~
{: .language-text}

## Bulk or offline access (optional)

While this lesson focuses on using the **OBIS API** and the `robis` / `pyobis` packages for
programmatic queries, OBIS also provides complete data exports for large-scale or offline use.

* OBIS publishes its full occurrence data archive on the
  **AWS Open Data Registry**:
  [https://registry.opendata.aws/obis/](https://registry.opendata.aws/obis/)
* Technical details and examples are maintained in the
  **OBIS Open Data GitHub repository**:
  [https://github.com/iobis/obis-open-data](https://github.com/iobis/obis-open-data)

> These exports contain the same occurrence records available through the API,
> formatted as CSV and GeoParquet files for analysis in cloud or high-performance environments.
> For most OTN-focused analyses, the API-based approach taught here is sufficient,
> but bulk exports are ideal if you need **full OBIS datasets** or **offline workflows**.

## Anatomy of an OBIS query (OTN-focused)

An OBIS request is a URL with filters.
The example below retrieves blue shark records contributed by OTN.

~~~
https://api.obis.org/v3/occurrence?
nodeid=68f83ea7-69a7-44fd-be77-3c3afd6f3cf8&
scientificname=Prionace%20glauca&
startdate=2000-01-01&
size=100
~~~

{: .language-text}

### What each part means

> **nodeid** — restricts results to the OTN node
> **scientificname** — filters by species (for example, *Prionace glauca*)
> **startdate / enddate** — sets a time window
> **geometry** — filters by region (polygon or bounding box in WKT)
> **datasetid** — limits the search to a specific OTN dataset
> **size / from** — controls paging through large results
> **fields** — specifies which columns to return for smaller, faster responses

## Your first OBIS query

The simplest OBIS query includes only two filters: a species name and the OTN node UUID.
The example below retrieves blue shark (*Prionace glauca*) records contributed by OTN.

### R (using robis)

~~~
# install.packages("robis")   # run once
library(robis)

OTN <- "68f83ea7-69a7-44fd-be77-3c3afd6f3cf8"

blue <- occurrence("Prionace glauca", nodeid = OTN, size = 500)

head(blue)
~~~
{: .language-r}

### Python (using pyobis)

~~~
# pip install pyobis pandas   # run once
from pyobis import occurrences

OTN = "68f83ea7-69a7-44fd-be77-3c3afd6f3cf8"

blue = occurrences.search(
    scientificname="Prionace glauca",
    nodeid=OTN,
    size=500
).execute()

print(blue.head())
~~~
{: .language-python}

## Adding filters

You can add filters to make OBIS queries more specific.
The most common options are:

* **Time window** (`startdate`, `enddate`)
* **Place** (`geometry=` using a WKT polygon or bounding box in longitude/latitude)
* **Dataset** (`datasetid=`)
* **Fields** (`fields=` to return only selected columns)

### R

~~~
# Time filter (since 2000)
blue_time <- occurrence("Prionace glauca", nodeid = OTN, startdate = "2000-01-01")

# Place filter (box in Gulf of St. Lawrence)
wkt <- "POLYGON((-70 40, -70 50, -55 50, -55 40, -70 40))"
blue_space <- occurrence("Prionace glauca", nodeid = OTN, geometry = wkt)

# Dataset filter (replace with an actual dataset UUID)
# blue_ds <- occurrence("Prionace glauca", nodeid = OTN, datasetid = "DATASET-UUID")

# Return selected fields only
blue_lean <- occurrence("Prionace glauca", nodeid = OTN,
  fields = c("scientificName", "eventDate", "decimalLatitude",
             "decimalLongitude", "datasetName"))
~~~
{: .language-r}

### Python

~~~
# Time filter (since 2000)
blue_time = occurrences.search(
    scientificname="Prionace glauca", nodeid=OTN, startdate="2000-01-01"
).execute()

# Place filter (box in Gulf of St. Lawrence)
wkt = "POLYGON((-70 40, -70 50, -55 50, -55 40, -70 40))"
blue_space = occurrences.search(
    scientificname="Prionace glauca", nodeid=OTN, geometry=wkt
).execute()

# Dataset filter (replace with an actual dataset UUID)
# blue_ds = occurrences.search(
#     scientificname="Prionace glauca", nodeid=OTN, datasetid="DATASET-UUID"
# ).execute()

# Return selected fields only
blue_lean = occurrences.search(
    scientificname="Prionace glauca", nodeid=OTN,
    fields="scientificName,eventDate,decimalLatitude,decimalLongitude,datasetName"
).execute()
~~~
{: .language-python}

**Tips**

* Always **drop NAs** in latitude/longitude before mapping.
* Dates come back as text — convert to `Date` (R) or `datetime` (Python) if you need time plots.
* For large datasets, **paginate** with `size` + `from` (Python) or repeat calls with `from` (R).


## Follow-Along: “Where are the Blue Sharks?”

We’ll walk through a full workflow:

* pull **blue shark (*Prionace glauca*)** records contributed by **OTN**,
* focus on the **NW Atlantic**,
* make an **interactive map** and a couple of **time-series views**.

> **Install once**

```bash
pip install pyobis pandas folium matplotlib
````

### 1) Imports & Setup

Load the libraries, set the OTN node UUID, species, and a bounding box (WKT polygon) for the NW Atlantic.

```python
from pyobis import occurrences, dataset
import pandas as pd
import folium
from folium.plugins import HeatMap, MarkerCluster
import matplotlib.pyplot as plt

OTN = "68f83ea7-69a7-44fd-be77-3c3afd6f3cf8"
SPECIES = "Prionace glauca"  # blue shark
WKT = "POLYGON((-80 30, -80 52, -35 52, -35 30, -80 30))"
```

### 2) Peek at OTN datasets

This shows which datasets under OTN actually contain blue shark records.

```python
ds = dataset.search(nodeid=OTN, limit=100, offset=0).execute()
pd.DataFrame(ds["results"])[["id","title"]].head(10)
```

### 3) Query OBIS for Blue Shark

We add filters: **species + node + region + time window**.

```python
df = occurrences.search(
    scientificname=SPECIES,
    nodeid=OTN,
    geometry=WKT,
    startdate="2000-01-01",
    size=5000,
    fields="id,scientificName,eventDate,decimalLatitude,decimalLongitude,datasetName"
).execute()
```

### 4) Clean the results

Drop rows without coordinates, parse event dates, and check the shape.

```python
df = df.dropna(subset=["decimalLatitude","decimalLongitude"]).copy()
df["eventDate"] = pd.to_datetime(df["eventDate"], errors="coerce")
df = df.dropna(subset=["eventDate"])
print(df.shape)
df.head()
```

### 5) Quick sanity checks

See which datasets dominate and what the date range looks like.

```python
print("Top datasets:\n", df["datasetName"].value_counts().head(10))
print("Date range:", df["eventDate"].min(), "→", df["eventDate"].max())
```

### 6) Interactive Map

Plot both individual points (sampled so the map stays fast) and a density heatmap.

```python
center = [df["decimalLatitude"].median(), df["decimalLongitude"].median()]
m = folium.Map(location=center, zoom_start=4, tiles="OpenStreetMap")

# Markers
sample = df.sample(min(len(df), 2000), random_state=42)
mc = MarkerCluster(name="Blue shark points").add_to(m)
for _, r in sample.iterrows():
    tip = f"{r['scientificName']} • {str(r['eventDate'])[:10]}"
    folium.CircleMarker([r["decimalLatitude"], r["decimalLongitude"]],
                        radius=3, tooltip=tip).add_to(mc)

# Heatmap
HeatMap(df[["decimalLatitude","decimalLongitude"]].values.tolist(),
        name="Density", radius=14, blur=22, min_opacity=0.25).add_to(m)

folium.LayerControl().add_to(m)
m.save("otn_blue_shark_map.html")
print("Saved → otn_blue_shark_map.html")
```

### 7) Yearly & Monthly Patterns

Summarize how records are distributed in time.

```python
# Records per year
df["eventDate"].dt.year.value_counts().sort_index().plot(kind="bar", title="Records per year")
plt.xlabel("Year"); plt.ylabel("Records"); plt.show()

# Records by month
df["eventDate"].dt.month.value_counts().sort_index().plot(kind="bar", title="Records by month")
plt.xlabel("Month"); plt.ylabel("Records"); plt.show()
```

## Common pitfalls & quick fixes

* **Empty results?** Loosen filters (remove `geometry`, broaden dates, drop `datasetid`).
* **Slow/large queries?** Use `fields=...`, smaller regions, and paginate with `size` + `from`.
* **Missing coordinates?** Drop NA lat/lon before mapping.
* **CRS confusion?** OBIS returns WGS84 (EPSG:4326); mapping expects lon/lat.


## Exercises

1. Query a **different species** (e.g., `"Gadus morhua"`) restricted to OTN.
2. Find a specific OTN dataset and filter occurrences by `datasetid`.
3. Compare **recent vs historical** records with `startdate` / `enddate`.
4. Change the `geometry` to your own study region and map results.
5. Save results:

   * **Python:** `df.to_csv("export.csv", index=False)`
   * **R:** `write.csv(salmon, "export.csv", row.names = FALSE)`

---

## Assessment

> ## Check your understanding
>
> You want **blue shark** (*Prionace glauca*) records **from OTN only**, since **2000-01-01**, via the OBIS API.
> Which URL is correct?
>
> 1. `https://api.obis.org/v3/occurrence?scientificname=Prionace glauca&node=OTN&startdate=2000-01-01`
>
> 2. `https://api.obis.org/v3/occurrence?scientificname=Prionace%20glauca&nodeid=68f83ea7-69a7-44fd-be77-3c3afd6f3cf8&startdate=2000-01-01&size=500`
>
> 3. `https://api.obis.org/v3/occurrence?scientificName=Prionace%20glauca&nodeid=OTN&since=2000-01-01`
>
> > ## Solution
> >
> > **Option 2.**
> > Uses the correct parameter names (`scientificname`, `nodeid`, `startdate`), correctly URL-encodes the space in the species name, includes the OTN **node UUID**, and adds `size` to control paging.
> > Option 1 uses the wrong param for the node and doesn’t encode the space; Option 3 uses incorrect parameter names.
> {: .solution}
{: .challenge}

---

> ## Spot the paging issue
>
> Your query returns only **500 records**, even though you expect more:
>
> ```
> https://api.obis.org/v3/occurrence?scientificname=Prionace%20glauca&nodeid=68f83ea7-69a7-44fd-be77-3c3afd6f3cf8
> ```
>
> What would you add to retrieve additional pages?
>
> > ## Solution
> >
> > Use **paging parameters**: increase a page size (e.g., `&size=5000`) and iterate with **`from`** (offset), e.g. `&from=0`, `&from=5000`, `&from=10000`, … until a page comes back empty.
> > Example:
> > `...&size=5000&from=0`
> {: .solution}
{: .challenge}

---

> ## Construct a filtered query
>
> Restrict to the **NW Atlantic** box and return only a **slim set of fields**.
> Use *blue shark*, the **OTN UUID**, a **time window since 2000-01-01**, and this WKT polygon:
> `POLYGON((-80 30, -80 52, -35 52, -35 30, -80 30))`
>
> > ## Solution
> >
> > ```
> > https://api.obis.org/v3/occurrence?
> > scientificname=Prionace%20glauca&
> > nodeid=68f83ea7-69a7-44fd-be77-3c3afd6f3cf8&
> > geometry=POLYGON((-80%2030,%20-80%2052,%20-35%2052,%20-35%2030,%20-80%2030))&
> > startdate=2000-01-01&
> > size=5000&
> > fields=id,scientificName,eventDate,decimalLatitude,decimalLongitude,datasetName
> > ```
> >
> > Notes: URL-encode spaces in WKT; `fields=` keeps the response small and faster to parse.
> {: .solution}
{: .challenge}

---

> ## Diagnose empty results
>
> This query returns **zero** rows. Which two fixes are most likely to help?
>
> ```
> https://api.obis.org/v3/occurrence?scientificname=Prionace%20glauca&nodeid=68f83ea7-69a7-44fd-be77-3c3afd6f3cf8&geometry=POLYGON((-70%2060,%20-70%2062,%20-55%2062,%20-55%2060,%20-70%2060))&startdate=2024-01-01&enddate=2024-01-31
> ```
>
> A) Swap lat/lon to `POLYGON((60 -70, 62 -70, 62 -55, 60 -55, 60 -70))`
> B) Broaden the **time window** or **region**
> C) Remove `nodeid` so non-OTN records are included
> D) Use `scientificName=` instead of `scientificname=`
>
> > ## Solution
> >
> > **B and C are plausible**, depending on your aim. If you must stay with OTN, try **B** first (expand dates/area). If any OBIS records are acceptable, **C** will increase results.
> > A is incorrect (OBIS expects lon,lat in WKT already); D is just a casing variant—`scientificname` is correct.
> {: .solution}
{: .challenge}

---

> ## Short answer
>
> Why use `fields=` when querying OBIS for mapping?
>
> > ## Solution
> >
> > It **reduces payload** (faster, cheaper) and returns only what mapping needs (e.g., `scientificName,eventDate,decimalLatitude,decimalLongitude`), avoiding dozens of unused columns.
> {: .solution}
{: .challenge}

---

> ## True or False
>
> OBIS coordinates are returned in **WGS84 (EPSG:4326)** and the WKT `geometry` filter expects coordinates in **lon,lat** order.
>
> > ## Solution
> >
> > **True.** OBIS uses WGS84; WKT polygons and bboxes are specified in **longitude, latitude** order.
> {: .solution}
{: .challenge}

---

> ## Code reading (R)
>
> What two lines would you add to this `robis` call to **drop missing coordinates** and **parse dates** for plotting?
>
> ```r
> library(robis); library(dplyr)
> OTN <- "68f83ea7-69a7-44fd-be77-3c3afd6f3cf8"
> df <- occurrence("Prionace glauca", nodeid = OTN, size = 5000)
> # add lines here
> ```
>
> > ## Solution
> >
> > ```r
> > df <- df %>% filter(!is.na(decimalLatitude), !is.na(decimalLongitude))
> > df$eventDate <- as.POSIXct(df$eventDate, tz = "UTC", tryFormats = c("%Y-%m-%d","%Y-%m-%dT%H:%M:%S","%Y-%m-%dT%H:%M:%SZ"))
> > ```
> {: .solution}
 {: .challenge}

---

> ## Code reading (Python)
>
> Fill in the missing **paging** to gather up to **20,000** records (4 pages of 5,000).
>
> ```python
> from pyobis import occurrences
> OTN = "68f83ea7-69a7-44fd-be77-3c3afd6f3cf8"
> pages = []
> for offset in [____]:
>     page = occurrences.search(
>         scientificname="Prionace glauca",
>         nodeid=OTN,
>         size=5000,
>         from_=offset,
>         fields="id,scientificName,eventDate,decimalLatitude,decimalLongitude"
>     ).execute()
>     pages.append(page)
> ```
>
> > ## Solution
> >
> > ```python
> > for offset in [0, 5000, 10000, 15000]:
> >     ...
> > ```
> {: .solution}
{: .challenge}

---

