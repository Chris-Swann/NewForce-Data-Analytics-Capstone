TRUNCATE TABLE golden_ticket_races;

SELECT *
FROM race_results;

-- This query aggregates race participation and performance metrics by race and gender.
-- It calculates:
--   • Total starters per gender and overall
--   • Percentage of starters by gender within each race
--   • Total DNFs (Did Not Finish) and DNF rate per gender
-- It also classifies races by region (US vs Non-US) based on latitude/longitude,
-- and by type (Golden Ticket vs Non-Golden Ticket).
-- The GROUPING SETS clause provides both gender-specific and overall summaries.

SELECT 
    rim.race_id,
    rim.race_name,
    CASE 
        WHEN rim.latitude BETWEEN 24 AND 49 AND rim.longitude BETWEEN -125 AND -66 THEN 'US'
        ELSE 'Non-US'
    END AS race_region,
    rim.race_date,
    rim.year,
    CASE WHEN rim.golden_ticket THEN 'Golden Ticket' ELSE 'Non-Golden Ticket' END AS race_type,
    COALESCE(rr.gender, 'Overall') AS gender,
    COUNT(*) AS total_starters,
    ROUND(
        COUNT(*)::numeric / SUM(COUNT(*)) OVER (PARTITION BY rim.race_id) * 100, 2
	    ) AS pct_gender_starters,
	    SUM(CASE WHEN rr.status = 'DNF' THEN 1 ELSE 0 END) AS total_dnfs,
	    ROUND(SUM(CASE WHEN rr.status = 'DNF' THEN 1 ELSE 0 END)::numeric / COUNT(*) * 100, 2) AS dnf_rate_pct
FROM race_id_master rim
JOIN race_results rr 
    ON TRIM(rim.race_id) = TRIM(rr.race_id::TEXT)
    AND rr.year = rim.year
WHERE rr.gender IN ('M', 'F')
GROUP BY GROUPING SETS (
    (rim.race_id, rim.race_name, rim.race_date, rim.year, rim.golden_ticket, rr.gender, rim.latitude, rim.longitude),
    (rim.race_id, rim.race_name, rim.race_date, rim.year, rim.golden_ticket, rim.latitude, rim.longitude)
)
ORDER BY rim.race_name, rim.year, gender;



SELECT
    g.race_id AS GT_Race_ID,
    rim.race_name AS GT_Race_Name,
    COALESCE(nm.normalized_name, LOWER(TRIM(g.name))) AS GT_Normalized_Name,
    g.gender AS GT_Gender,
    g.ticket_position,
    rr.time AS GT_Time,
    -- Western States data now from race_results
    rr_ws.series_id AS WS_Series_ID,
    rr_ws.race_id AS WS_Race_ID,
    rr_ws.race_date AS WS_Date,
    rr_ws.year AS WS_Year,
    rr_ws.rank AS WS_Rank,
    rr_ws.status AS WS_Status,
    rr_ws.nationality,
    rr_ws.gender_rank AS WS_Gender_Rank,
    rr_ws.age_category,
    rr_ws.time AS WS_Time,
    rr_ws.race_name AS WS_Race
FROM golden_ticket_races g
LEFT JOIN race_id_master rim ON g.race_id = rim.race_id
LEFT JOIN name_mapping nm ON LOWER(TRIM(g.name)) = LOWER(TRIM(nm.alias_name))
-- Western States now from race_results
LEFT JOIN race_results rr_ws ON CAST(g.ws_id AS INTEGER) = rr_ws.race_id
LEFT JOIN name_mapping nm2 ON LOWER(TRIM(rr_ws.name)) = LOWER(TRIM(nm2.alias_name))
-- Other race results
LEFT JOIN race_results rr ON CAST(g.race_id AS INTEGER) = rr.race_id
LEFT JOIN name_mapping nm_rr ON LOWER(TRIM(rr.name)) = LOWER(TRIM(nm_rr.alias_name))
WHERE COALESCE(nm.normalized_name, LOWER(TRIM(g.name))) = COALESCE(nm2.normalized_name, LOWER(TRIM(rr_ws.name)))
  AND COALESCE(nm.normalized_name, LOWER(TRIM(g.name))) = COALESCE(nm_rr.normalized_name, LOWER(TRIM(rr.name)))
  AND rr_ws.race_name = 'Western States'
ORDER BY ws_date;



SELECT WS_Year, COUNT(*) AS Total_Tickets, 
FROM golden_ticket_races
WHERE WS_Year BETWEEN 2022 AND 2025
GROUP BY WS_Year
ORDER BY WS_Year;



SELECT WS_Year, Gender, COUNT(*) AS Tickets
FROM golden_ticket_races
WHERE WS_Year BETWEEN 2022 AND 2025
GROUP BY WS_Year, Gender
ORDER BY WS_Year, Gender;


SELECT Name, COUNT(*) AS Golden_Tickets
FROM golden_ticket_races
GROUP BY Name
HAVING COUNT(*) > 1
ORDER BY Golden_Tickets DESC;


SELECT WS_Year, COUNT (*)COUNT(*) AS DNS_Count
FROM golden_ticket_races
WHERE DNS_Flag = TRUE
GROUP BY WS_Year
ORDER BY WS_Year;


SELECT ws_year,
       AVG(ticket_position) AS avg_ticket_position,
       AVG(ws_rank) AS avg_ws_rank
FROM gt_ws_perf
WHERE ws_status = 'Finisher'
GROUP BY ws_year
ORDER BY ws_year;

CREATE TABLE all_race_results (
    series_id INTEGER,
    race_id INTEGER,
    race_date DATE,
    year INTEGER,
    rank VARCHAR(20),
    status VARCHAR(50),
    name VARCHAR(255),
    nationality VARCHAR(50),
    gender VARCHAR(10),
    gender_rank INTEGER,
    age_category VARCHAR(50),
    time VARCHAR(20),
    race_name VARCHAR(255),
    race_loc VARCHAR(255),
    race_dist VARCHAR(10)
);

WITH RankedResults AS (
    SELECT
        race_id,
        race_name,
        gender,
        name,
        time,
        year,
        series_id,
        gender_rank::integer
    FROM all_race_results
    WHERE status = 'Finisher'
),
TopFinishers AS (
    SELECT *
    FROM RankedResults
    WHERE gender_rank <= 10
      AND series_id = 17002
),
NextYearResults AS (
    SELECT *
    FROM all_race_results
    WHERE series_id = 17002
)
SELECT
    tf.name AS runner_name,
    tf.gender AS original_gender,
    tf.race_name AS original_race,
    tf.year AS original_year,
    tf.gender_rank AS original_rank,
    tf.time AS original_time,
    ny.year AS next_year,
    ny.gender_rank AS next_rank,
    ny.time AS next_time,
    ny.status AS next_status
FROM TopFinishers tf
LEFT JOIN NextYearResults ny
    ON LOWER(TRIM(tf.name)) = LOWER(TRIM(ny.name))
   AND ny.year = tf.year + 1
ORDER BY
    tf.year, tf.gender, tf.gender_rank;
