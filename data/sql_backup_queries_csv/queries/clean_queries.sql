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




-- This query joins the golden_ticket_races table with the western_states_2022_2025 table
-- and uses a name_mapping table to normalize runner names. It applies COALESCE to replace
-- name variations with a standardized version when available, ensuring that matches occur
-- even if names differ across datasets (e.g., reversed order, initials, or extra middle names).
-- The WHERE clause compares normalized names from both datasets for accurate matching.

SELECT
    g.race_id AS GT_Race_ID,
	rim.race_name AS GT_Race_Name,
    COALESCE(nm.normalized_name, LOWER(TRIM(g.name))) AS GT_Normalized_Name,
    g.gender AS GT_Gender,
    g.ticket_position,
	rr.time,
    g.ws_year,
    g.ws_id AS GT_WS_ID,
    w.Series_ID,
    w.Race_ID AS WS_Race_ID,
    w.Race_Date AS WS_Date,
    w.Year AS WS_Year,
    w.Rank AS WS_Rank,
    w.Status AS WS_Status,
    COALESCE(nm2.normalized_name, LOWER(TRIM(w.Name))) AS WS_Normalized_Name,
    w.Nationality,
    w.Gender AS WS_Gender,
    w.Gender_Rank AS WS_Gender_Rank,
    w.Age_Category,
    w.Time AS WS_Time,
    w.Race_Name AS WS_Race,
    w.Race_Loc,
    w.Race_Dist
FROM golden_ticket_races g
LEFT JOIN race_id_master rim ON g.race_id = rim.race_id
LEFT JOIN name_mapping nm ON LOWER(TRIM(g.name)) = LOWER(TRIM(nm.alias_name))
JOIN western_states_2022_2025 w ON CAST(g.ws_id AS INTEGER) = w.Race_ID
LEFT JOIN name_mapping nm2 ON LOWER(TRIM(w.Name)) = LOWER(TRIM(nm2.alias_name))
LEFT JOIN race_results rr ON CAST(g.race_id AS INTEGER) = rr.race_id
LEFT JOIN name_mapping nm_rr ON LOWER(TRIM(rr.name)) = LOWER(TRIM(nm_rr.alias_name))
WHERE COALESCE(nm.normalized_name, LOWER(TRIM(g.name))) = COALESCE(nm2.normalized_name, LOWER(TRIM(w.Name)))
  AND COALESCE(nm.normalized_name, LOWER(TRIM(g.name))) = COALESCE(nm_rr.normalized_name, LOWER(TRIM(rr.name)));

SELECT
    g.race_id AS GT_Race_ID,
    rim.race_name AS GT_Race_Name,
    COALESCE(nm.normalized_name, LOWER(TRIM(g.name))) AS GT_Normalized_Name,
    g.gender AS GT_Gender,
    g.ticket_position,
    rr.time,
    g.ws_year,
    g.ws_id AS GT_WS_ID,
    w.Series_ID,
    w.Race_ID AS WS_Race_ID,
    w.Race_Date AS WS_Date,
    w.Year AS WS_Year,
    w.Rank AS WS_Rank,
    CASE 
        WHEN w.Race_ID IS NULL THEN 'DNS'
        ELSE w.Status
    END AS WS_Status,
    COALESCE(nm2.normalized_name, LOWER(TRIM(w.Name))) AS WS_Normalized_Name,
    w.Nationality,
    w.Gender AS WS_Gender,
    w.Gender_Rank AS WS_Gender_Rank,
    w.Age_Category,
    w.Time AS WS_Time,
    w.Race_Name AS WS_Race,
    w.Race_Loc,
    w.Race_Dist
FROM golden_ticket_races g
LEFT JOIN race_id_master rim ON g.race_id = rim.race_id
LEFT JOIN name_mapping nm ON LOWER(TRIM(g.name)) = LOWER(TRIM(nm.alias_name))
LEFT JOIN name_mapping nm2 ON LOWER(TRIM(w.Name)) = LOWER(TRIM(nm2.alias_name))
LEFT JOIN western_states_2022_2025 w 
    ON CAST(g.ws_id AS INTEGER) = w.Race_ID
    AND COALESCE(nm.normalized_name, LOWER(TRIM(g.name))) = COALESCE(nm2.normalized_name, LOWER(TRIM(w.Name)))
LEFT JOIN race_results rr ON CAST(g.race_id AS INTEGER) = rr.race_id
LEFT JOIN name_mapping nm_rr ON LOWER(TRIM(rr.name)) = LOWER(TRIM(nm_rr.alias_name))
WHERE COALESCE(nm.normalized_name, LOWER(TRIM(g.name))) = COALESCE(nm_rr.normalized_name, LOWER(TRIM(rr.name)));


SELECT *
FROM golden_ticket_races;


SELECT
    g.race_id AS GT_Race_ID,
    rim.race_name AS GT_Race_Name,
    COALESCE(nm.normalized_name, LOWER(TRIM(g.name))) AS GT_Normalized_Name,
    g.gender AS GT_Gender,
    g.ticket_position,
    rr.time AS GT_Time,
    -- Western States data from race_results
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
    rr_ws.race_name AS WS_Race,
    -- Normalized names for WS and RR
    COALESCE(nm2.normalized_name, LOWER(TRIM(rr_ws.name))) AS WS_Normalized_Name,
    COALESCE(nm_rr.normalized_name, LOWER(TRIM(rr.name))) AS RR_Normalized_Name
FROM golden_ticket_races g
LEFT JOIN race_id_master rim ON g.race_id = rim.race_id
-- Name mapping for golden ticket
LEFT JOIN name_mapping nm ON LOWER(TRIM(g.name)) = LOWER(TRIM(nm.alias_name))
-- Western States results
LEFT JOIN race_results rr_ws ON CAST(g.ws_id AS INTEGER) = rr_ws.race_id
LEFT JOIN name_mapping nm2 ON LOWER(TRIM(rr_ws.name)) = LOWER(TRIM(nm2.alias_name))
-- Other race results
LEFT JOIN race_results rr ON CAST(g.race_id AS INTEGER) = rr.race_id
LEFT JOIN name_mapping nm_rr ON LOWER(TRIM(rr.name)) = LOWER(TRIM(nm_rr.alias_name))
-- Optional filter for Western States only
WHERE rr_ws.race_name = 'Western States';


SELECT DISTINCT name, LENGTH(name), HEX(name)
FROM (
  SELECT name FROM golden_ticket_races WHERE LOWER(name) LIKE '%vincent%'
  UNION
  SELECT name FROM race_results WHERE LOWER(name) LIKE '%vincent%'
) AS names;



WITH normalized_gt AS (
    SELECT 
        g.*, 
        LOWER(TRIM(g.name)) AS norm_name
    FROM golden_ticket_races g
),
normalized_ws AS (
    SELECT 
        rr_ws.*, 
        LOWER(TRIM(rr_ws.name)) AS norm_name
    FROM race_results rr_ws
    WHERE rr_ws.race_name = 'Western States'
),
normalized_rr AS (
    SELECT 
        rr.*, 
        LOWER(TRIM(rr.name)) AS norm_name
    FROM race_results rr
),
normalized_map AS (
    SELECT 
        alias_name, 
        normalized_name, 
        LOWER(TRIM(alias_name)) AS norm_alias
    FROM name_mapping
)
SELECT
    gt.race_id AS GT_Race_ID,
    rim.race_name AS GT_Race_Name,
    COALESCE(nm.normalized_name, gt.norm_name) AS GT_Normalized_Name,
    gt.gender AS GT_Gender,
    gt.ticket_position,
    rr.time AS GT_Time,
    -- Western States data
    ws.series_id AS WS_Series_ID,
    ws.race_id AS WS_Race_ID,
    ws.race_date AS WS_Date,
    ws.year AS WS_Year,
    ws.rank AS WS_Rank,
    ws.status AS WS_Status,
    ws.nationality,
    ws.gender_rank AS WS_Gender_Rank,
    ws.age_category,
    ws.time AS WS_Time,
    ws.race_name AS WS_Race,
    COALESCE(nm_ws.normalized_name, ws.norm_name) AS WS_Normalized_Name,
    COALESCE(nm_rr.normalized_name, rr.norm_name) AS RR_Normalized_Name
FROM normalized_gt gt
LEFT JOIN race_id_master rim ON gt.race_id = rim.race_id
-- Name mapping for GT
LEFT JOIN normalized_map nm ON gt.norm_name = nm.norm_alias
-- Western States results
LEFT JOIN normalized_ws ws ON CAST(gt.ws_id AS INTEGER) = ws.race_id
LEFT JOIN normalized_map nm_ws ON ws.norm_name = nm_ws.norm_alias
-- Other race results
LEFT JOIN normalized_rr rr ON CAST(gt.race_id AS INTEGER) = rr.race_id
LEFT JOIN normalized_map nm_rr ON rr.norm_name = nm_rr.norm_alias;
