# Data Dictionary -- Race Metadata YAML Specifications

This project uses a set of YAML schemas to define metadata
for ultramarathon events pulled from major timing and results
platforms. These YAML files support scraping pipelines, results
harmonization, reproducibility, and standardized integration across
multiple datasets and data sources.

------------------------------------------------------------------------

## 1. UTMB World -- Event Index Schema (`utmb_world_utmb_index`)

Metadata for races sourced from **UTMB World**, including annual event
identifiers and UTMB-specific race URIs.

### **YAML Structure**

``` yaml
dates:
  <year>: <yyyy-mm-dd>       # Race date

race_dist: <string>          # e.g. "50M", "100K", "100M"
series_id: <integer>         # UTMB World series identifier (e.g. 1341 as found in 1341.lakesonoma50milerlakesonoma50)
race_loc: <string>           # Race Location
race_name: <string>          # Race Name

races:
  <year>:
    race_id: <integer>       # Assigned by user (no unique id in url for each year)
    race_uri: <string>       # UTMB slug or endpoint path copied from URL (e.g. 1341.lakesonoma50milerlakesonoma50)
```

### **Description**

-   Stores per-year UTMB identifiers and URLs.
-   Ensures accurate linking to UTMB results pages, which often change
    yearly.
-   Used to programmatically fetch, validate, and map UTMB World race
    results.

------------------------------------------------------------------------

## 2. UltraSignup Metadata Schema (`ultrasignup`)

Metadata for races tracked through **UltraSignup**, including yearly
race IDs.

### **YAML Structure**

``` yaml
race_name: <string>        # Race Name
race_loc: <string>         # Race Location
race_dist: <string>        # e.g., "100K"
series_id: <integer>       # Assigned by user

race_ids:
  <year>: <integer>        # Year-specific UltraSignup race ID (found in URL)
```

### **Description**

-   UltraSignup assigns unique event IDs for each year.
-   The scraper retrieves race dates dynamically and normalizes them to
    `MM/DD/YYYY`.
-   Maintains compatibility across multiple years of historical data.

------------------------------------------------------------------------

## 3. UTMB Mont-Blanc / UTMB World -- Event History Schema (`mont_blanc_utmb_world`)

Metadata for the UTMB Mont-Blanc series, which undergoes frequent
naming, sponsorship, and endpoint changes that require annual tracking.

### **YAML Structure**

``` yaml
dates:
  <year>: <YYYY-MM-DD>       # Manually input by user

race_dist: <string>
race_loc: <string>
race_name: <string>

race_uris:
  <year>: <string>           # Year-specific UTMB results slug copied from URL (e.g. 37038.grindstonetrailrunningfestivalbyutmb100k)
```

------------------------------------------------------------------------

## 4. EDS Results Schema (`edsresults`)

Metadata for races sourced from **edsresults**.

### **YAML Structure**

``` yaml
race_name: <string>
race_loc: <string>
race_dist: <string>
series_id: <integer>        # Timing provider's race identifier

race_date:
  <year>: <yyyy-mm-dd>      # Official race date

race_slugs:
  <year>: <string>          # Year-specific slug used for scraping results (e.g. "bandera16" found in URL)
```

### **Description**

-  Strucure will be updated to automatically assign Race_ID for each year. Currently, assigned manually after scraping.

------------------------------------------------------------------------

# Common Conventions Across All YAML Schemas

### ✔ Year-Keyed Fields

Most YAML structures use a `<year>: value` pattern to account for: -
Annual race ID changes\
- URL slugs that differ year to year

### ✔ Distance Format Standardization

`race_dist` follows a consistent shorthand: - `"50M"` → 50 miles\
- `"100K"` → 100 kilometers\
- `"100M"` → 100 miles

### ✔ Date Formatting

Dates are ISO (`YYYY-MM-DD`)

Consistency enables clean data ingestion and transformation.

------------------------------------------------------------------------

# Purpose and Use in the Repository

These YAML schemas provide the foundation for:

-   Consistent race metadata across multiple years\
-   Automated scraping pipelines\
-   Harmonized result ingestion from UTMB World, UltraSignup,
    proprietary timing platforms, and event websites\
-   Reproducible data processing\
-   Longitudinal performance analysis

Storing race metadata in structured YAML files allows the entire project
to avoid hard-coded URLs, event IDs, and ad hoc scraping
logic---dramatically improving maintainability and reliability.

------------------------------------------------------------------------

# Contributing New Race YAML Files

When adding a new event: 1. Follow the schema pattern for the relevant
source (UTMB, UltraSignup, etc.). 2. Include: - race name\
- location\
- distance\
- series or race identifier\
- per-year race IDs and/or slugs\
- per-year dates if available\
3. Use standardized date and distance formats.\
4. Validate YAML formatting before submitting a PR.

------------------------------------------------------------------------

# Summary

This data dictionary outlines the structure and purpose of all YAML
metadata files in the repository. These schemas ensure that scraping
scripts, analysis notebooks, and downstream tools all share the same
consistent reference for race information---making the entire system
robust, scalable, and ready for long-term maintenance.
