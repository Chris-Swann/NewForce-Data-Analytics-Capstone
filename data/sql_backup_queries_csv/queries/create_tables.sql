-- Create results_combined_master table. Using placeholder table first.

DROP TABLE IF EXISTS results_combined_master_raw;

CREATE TABLE results_combined_master_raw (
    series_id     TEXT,
    race_id       TEXT,
    race_date     TEXT,
    year          TEXT,
    rank          TEXT,
    status        TEXT,
    name          TEXT,
    nationality   TEXT,
    gender        TEXT,
    gender_rank   TEXT,
    age_category  TEXT,
    time          TEXT,
    race_name     TEXT,
    race_loc      TEXT,
    race_dist     TEXT
);

DROP TABLE IF EXISTS results_combined_master;

CREATE TABLE results_combined_master (
    series_id      TEXT,
    race_id        TEXT,
    race_date      DATE,
    year           SMALLINT,
    rank           INTEGER,
    status         TEXT,
    name           TEXT,
    nationality    TEXT,
    gender         TEXT,
    gender_rank    INTEGER,
    age_category   TEXT,
    -- fraction-of-day from CSV
    time           NUMERIC(12,10),
    -- derived numeric seconds
    time_seconds   INTEGER,
    race_name      TEXT,
    race_loc       TEXT,
    race_dist      TEXT
);

INSERT INTO results_combined_master (
    series_id,
    race_id,
    race_date,
    year,
    rank,
    status,
    name,
    nationality,
    gender,
    gender_rank,
    age_category,
    time,
    time_seconds,
    race_name,
    race_loc,
    race_dist
)
SELECT
    NULLIF(TRIM(series_id), '')                           AS series_id,
    NULLIF(TRIM(race_id), '')                             AS race_id,
    CASE
        WHEN race_date IS NULL OR TRIM(race_date) = '' THEN NULL
        ELSE to_date(TRIM(race_date), 'MM/DD/YYYY')
    END                                                   AS race_date,
    NULLIF(TRIM(year), '')::smallint                      AS year,
    NULLIF(TRIM(rank), '')::int                           AS rank,
    NULLIF(TRIM(status), '')                              AS status,
    NULLIF(TRIM(name), '')                                AS name,
    NULLIF(TRIM(nationality), '')                         AS nationality,
    NULLIF(TRIM(gender), '')                              AS gender,
    NULLIF(TRIM(gender_rank), '')::int                    AS gender_rank,
    NULLIF(TRIM(age_category), '')                        AS age_category,
    NULLIF(TRIM(time), '')::numeric(12,10)                AS time,
    -- convert fraction of day → seconds
    CASE
        WHEN NULLIF(TRIM(time), '') IS NULL THEN NULL
        ELSE ROUND((NULLIF(TRIM(time), '')::numeric(12,10)) * 86400)::int
    END                                                   AS time_seconds,
    NULLIF(TRIM(race_name), '')                           AS race_name,
    NULLIF(TRIM(race_loc), '')                            AS race_loc,
    NULLIF(TRIM(race_dist), '')                           AS race_dist
FROM results_combined_master_raw;

SELECT
    series_id,
    race_id,
    race_date,
    year,
    name,
    time,
    time_seconds,
    TO_CHAR(make_interval(secs => time_seconds), 'HH24:MI:SS') AS time_hms,
	race_name,
	race_loc,
	race_dist
FROM results_combined_master
LIMIT 10;

SELECT *
FROM results_combined_master;

---------------------------------------------------------------------------------------------------

-- Create gt_master_table

CREATE TABLE gt_master_table (
    race_id             TEXT,
    series_id           TEXT,
    race_date           DATE,
    race_name           TEXT,
    actual_dist         NUMERIC(6,2),
    diff_index          NUMERIC(5,1),
    gender              TEXT,
    ticket_position     INTEGER,
    name                TEXT,
    nationality         TEXT,
    age_category        TEXT,
    gender_rank         INTEGER,
    ws_date             DATE,
    ws_year             SMALLINT,
    ws_id               TEXT,
    ws_finisher_flag    BOOLEAN,
    ws_dnf_flag         BOOLEAN,
    ws_dns_flag         BOOLEAN,
    gt_finish_time      NUMERIC(12,10),   -- fraction of day
    gt_pace             TEXT,             -- '7:26'
    ws_finish_time      NUMERIC(12,10),   -- fraction of day
    ws_pace             TEXT,             -- '11:15'
    ws_gender_rank      INTEGER,
    num_ws_finish       SMALLINT,
    days_to_ws          INTEGER
);

SELECT *
FROM gt_master_table;

---------------------------------------------------------------------------------------------------

-- Create table for course_metadata

CREATE TABLE course_metadata (
    series_id               TEXT,
    race_name               TEXT,
    race_class              TEXT,
    distance_mi             NUMERIC(8,2),
    elevation_gain_ft       INTEGER,
    elevation_loss_ft       INTEGER,
    max_elev_ft             INTEGER,
    min_elev_ft             INTEGER,
    elevation_range_ft      INTEGER,
    avg_grade_pct           NUMERIC(5,2),
    altitude_exposure_mi    NUMERIC(8,2),
    major_climb_count       INTEGER,
    longest_climb_ft        INTEGER,
    latitude                NUMERIC(10,6),
    longitude               NUMERIC(10,6),
    distance_km             NUMERIC(8,2),
    gain_m                  INTEGER,
    loss_m                  INTEGER,
    altitude_exposure_km    NUMERIC(8,2),
    effort_km               NUMERIC(10,2),
    difficulty_index        NUMERIC(6,1)
);

SELECT *
FROM course_metadata;

---------------------------------------------------------------------------------------------------

-- Create table for top_10_yoy_ws_perf

CREATE TABLE ws_top10_yoy (
    athlete_name          TEXT,
    athlete_gender        TEXT,
    age                   SMALLINT,
    age_group             TEXT,
    nationality           TEXT,
    race_name             TEXT,          
    original_year         SMALLINT,
    original_gender_rank  INTEGER,
    original_time         NUMERIC(12,10),  -- fraction of day
    next_year             SMALLINT,
    next_gender_rank      INTEGER,
    next_time             NUMERIC(12,10),  -- fraction of day
    next_status           TEXT,            
    num_ws_finishes       SMALLINT
);

SELECT *
FROM ws_top10_yoy;