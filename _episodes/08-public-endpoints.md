---
title: "Supplemental: Public Data Endpoints"
teaching: 10
exercises: 0
questions:
- "What public endpoints does OTN provide, and when should I use each?"
objectives:
- "Identify the Discovery Portal, GeoServer, OBIS, and ERDDAP."
- "Understand the purpose of each endpoint."
- "Select the right endpoint for mapping, biodiversity records, or tabular analysis."
keypoints:
- "Discovery Portal = searchable catalogue"
- "GeoServer = spatial layers (WFS/WMS)"
- "OBIS = biodiversity occurrence datasets (UUID-based)"
- "ERDDAP = analysis-ready tables with filtering"
---

## The Big Picture

The **Ocean Tracking Network (OTN)** makes much of its data publicly available. There isn’t just one access point — instead, OTN provides several endpoints, each designed for a different type of use.

-   **Discovery Portal** → the searchable catalogue of OTN datasets.
-   **GeoServer** → spatial data services for maps and GIS (stations, receivers, moorings).
-   **OBIS** → biodiversity/occurrence datasets (species records).
-   **ERDDAP** → analysis-ready tabular datasets with filtering and download options.

------------------------------------------------------------------------

![OTN Public Endpoints Diagram](../fig/Path_of_data.png)

------------------------------------------------------------------------

## Public Endpoints

-   **Discovery Portal (catalogue):** <https://members.oceantrack.org/data/discovery/bypublic.htm>

    -   Human-friendly entry point.
    -   Provides search and links to datasets across OTN systems.

-   **GeoServer (spatial layers):** <http://geoserver.oceantrack.org/geoserver/web/?1>

    -   Serves GIS-ready data via WFS/WMS (e.g., CSV, GeoJSON).
    -   Best for mapping stations, receivers, and moorings.
    -   Example: integrating OTN station layers in QGIS.
    -   → See: *GeoServer episode*.

-   **OBIS (biodiversity occurrences):** <https://obis.org/node/68f83ea7-69a7-44fd-be77-3c3afd6f3cf8>

    -   Global standard for species occurrence data.
    -   OTN contributes datasets with UUID identifiers.
    -   Ideal for querying animal presence/absence or species distribution.
    -   → See: *OBIS episode*.

-   **ERDDAP (tabular/time-series):** <https://erddap.oceantrack.org/erddap/index.html>

    -   Provides time-series and detection datasets in formats like CSV, JSON, NetCDF.
    -   Supports subsetting and reproducible queries.
    -   Suitable for analysis pipelines and scripting.
    -   → See: *ERDDAP episode*.

------------------------------------------------------------------------

### Which Endpoint Should I Use?

-   **Need spatial layers or GIS integration?** → **GeoServer**
-   **Need species occurrence data for biodiversity studies?** → **OBIS**
-   **Need tabular or time-series data for analysis?** → **ERDDAP**
-   **Not sure where to start?** → **Discovery Portal**

------------------------------------------------------------------------

### Private Data (OTN Collaborators)

For OTN-affiliated projects, additional **Detection Extracts** are available in secure project repositories under *Detection Extracts*. See documentation: <https://members.oceantrack.org/OTN/data/otn-detection-extract-documentation-matched-to-animals>

------------------------------------------------------------------------
