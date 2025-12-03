-- OVERALL COUNTS AND RATES

WITH summary AS (
    SELECT
        COUNT(*) FILTER (WHERE ws_finisher_flag) AS finisher_count,
        COUNT(*) FILTER (WHERE ws_dnf_flag)      AS dnf_count,
        COUNT(*) FILTER (WHERE ws_dns_flag)      AS dns_count
    FROM gt_master_table
)
SELECT
    finisher_count,
    dnf_count,
    dns_count,
    (finisher_count + dnf_count) AS finisher_dnf_total,
    -- Rates using only Finisher + DNF as denominator
    ROUND(
        100.0 * finisher_count / NULLIF(finisher_count + dnf_count, 0),
        1
    ) AS finisher_rate_pct,
    ROUND(
        100.0 * dnf_count / NULLIF(finisher_count + dnf_count, 0),
        1
    ) AS dnf_rate_pct,
    -- Optional: DNS rate versus ALL GT entries
    ROUND(
        100.0 * dns_count
        / NULLIF(finisher_count + dnf_count + dns_count, 0),
        1
    ) AS dns_rate_pct_overall
FROM summary;

-- COUNTS AND RATES (FINISHER/DNF) FOR GT/TOP10/WS

WITH gt_summary AS (
    SELECT
        COUNT(*) FILTER (WHERE ws_finisher_flag) AS gt_finisher_count,
        COUNT(*) FILTER (WHERE ws_dnf_flag)      AS gt_dnf_count
    FROM gt_master_table
    WHERE ws_year BETWEEN 2016 AND 2025
      AND ws_dns_flag = FALSE
),
ws_summary AS (
    SELECT
        COUNT(*) FILTER (WHERE status = 'Finisher') AS ws_finisher_count,
        COUNT(*) FILTER (WHERE status = 'DNF')      AS ws_dnf_count
    FROM results_combined_master
    WHERE race_name ILIKE 'Western States'
      AND year BETWEEN 2016 AND 2025
),
top10_summary AS (
    SELECT
        COUNT(*) FILTER (WHERE next_status ILIKE 'Finisher') AS top10_finisher_count,
        COUNT(*) FILTER (WHERE next_status ILIKE 'DNF')      AS top10_dnf_count
    FROM ws_top10_yoy
    WHERE next_year BETWEEN 2016 AND 2025
)
SELECT
    -- GT Recipients
    gt_finisher_count AS gt_finishers,
    gt_dnf_count AS gt_dnfs,
    ROUND(100.0 * gt_finisher_count / NULLIF(gt_finisher_count + gt_dnf_count, 0), 1) AS gt_finish_rate_pct,
    ROUND(100.0 * gt_dnf_count / NULLIF(gt_finisher_count + gt_dnf_count, 0), 1) AS gt_dnf_rate_pct,
    -- All WS Runners
    ws_finisher_count AS ws_finishers,
    ws_dnf_count AS ws_dnfs,
    ROUND(100.0 * ws_finisher_count / NULLIF(ws_finisher_count + ws_dnf_count, 0), 1) AS ws_finish_rate_pct,
    ROUND(100.0 * ws_dnf_count / NULLIF(ws_finisher_count + ws_dnf_count, 0), 1) AS ws_dnf_rate_pct,
    -- Top-10 Returners
    top10_finisher_count AS top10_finishers,
    top10_dnf_count AS top10_dnf,
    ROUND(100.0 * top10_finisher_count / NULLIF(top10_finisher_count + top10_dnf_count, 0), 1) AS top10_finish_rate_pct,
    ROUND(100.0 * top10_dnf_count / NULLIF(top10_finisher_count + top10_dnf_count, 0), 1) AS top10_dnf_rate_pct
FROM gt_summary, ws_summary, top10_summary;

-- COUNTS AND RATES (FINISHER/DNF) FOR GT/TOP10/WS
-- Exclude gt/top10 from ws. It is noted there is a difference of 8. One participant is accounted for but a more comprehensive 
-- analysis is required to determine the other 7. This will need to be performed at a later time.

WITH gt_summary AS (
    SELECT
        COUNT(*) FILTER (WHERE ws_finisher_flag) AS gt_finisher_count,
        COUNT(*) FILTER (WHERE ws_dnf_flag)      AS gt_dnf_count
    FROM gt_master_table
    WHERE ws_year BETWEEN 2016 AND 2025
      AND ws_dns_flag = FALSE
),
top10_summary AS (
    SELECT
        COUNT(*) FILTER (WHERE next_status ILIKE 'Finisher') AS top10_finisher_count,
        COUNT(*) FILTER (WHERE next_status ILIKE 'DNF')      AS top10_dnf_count
    FROM ws_top10_yoy
    WHERE next_year BETWEEN 2016 AND 2025
),
ws_summary AS (
    SELECT
        COUNT(*) FILTER (WHERE status = 'Finisher') AS ws_finisher_count,
        COUNT(*) FILTER (WHERE status = 'DNF')      AS ws_dnf_count
    FROM results_combined_master
    WHERE race_name ILIKE 'Western States'
      AND year BETWEEN 2016 AND 2025
	  AND (name, year) NOT IN (
		    SELECT name, ws_year FROM gt_master_table WHERE ws_year BETWEEN 2016 AND 2025
		    UNION
		    SELECT athlete_name, next_year FROM ws_top10_yoy WHERE next_year BETWEEN 2016 AND 2025
		)
)
SELECT
    -- GT Recipients
    gt_finisher_count AS gt_finishers,
    gt_dnf_count AS gt_dnfs,
    ROUND(100.0 * gt_finisher_count / NULLIF(gt_finisher_count + gt_dnf_count, 0), 1) AS gt_finish_rate_pct,
    ROUND(100.0 * gt_dnf_count / NULLIF(gt_finisher_count + gt_dnf_count, 0), 1) AS gt_dnf_rate_pct,
    -- All WS Runners (excluding GT & Top-10)
    ws_finisher_count AS ws_finishers,
    ws_dnf_count AS ws_dnfs,
    ROUND(100.0 * ws_finisher_count / NULLIF(ws_finisher_count + ws_dnf_count, 0), 1) AS ws_finish_rate_pct,
    ROUND(100.0 * ws_dnf_count / NULLIF(ws_finisher_count + ws_dnf_count, 0), 1) AS ws_dnf_rate_pct,
    -- Top-10 Returners
    top10_finisher_count AS top10_finishers,
    top10_dnf_count AS top10_dnfs,
    ROUND(100.0 * top10_finisher_count / NULLIF(top10_finisher_count + top10_dnf_count, 0), 1) AS top10_finish_rate_pct,
    ROUND(100.0 * top10_dnf_count / NULLIF(top10_finisher_count + top10_dnf_count, 0), 1) AS top10_dnf_rate_pct
FROM gt_summary, ws_summary, top10_summary;



WITH ws_all AS (
    SELECT COUNT(*) AS ws_total
    FROM results_combined_master
    WHERE race_name ILIKE 'Western States'
      AND year BETWEEN 2016 AND 2025
),
ws_excluded AS (
    SELECT COUNT(*) AS ws_excluded
    FROM results_combined_master
    WHERE race_name ILIKE 'Western States'
      AND year BETWEEN 2016 AND 2025
      AND (name, year) NOT IN (
            SELECT name, ws_year FROM gt_master_table WHERE ws_year BETWEEN 2016 AND 2025
            UNION
            SELECT athlete_name, next_year FROM ws_top10_yoy WHERE next_year BETWEEN 2016 AND 2025
        )
),
gt_rows AS (
    SELECT COUNT(*) AS gt_rows
    FROM gt_master_table
    WHERE ws_year BETWEEN 2016 AND 2025
),
top10_rows AS (
    SELECT COUNT(*) AS top10_rows
    FROM ws_top10_yoy
    WHERE next_year BETWEEN 2016 AND 2025
),
overlap_rows AS (
    SELECT COUNT(*) AS overlap_rows
    FROM (
        SELECT name, ws_year FROM gt_master_table WHERE ws_year BETWEEN 2016 AND 2025
        INTERSECT
        SELECT athlete_name, next_year FROM ws_top10_yoy WHERE next_year BETWEEN 2016 AND 2025
    ) sub
)
SELECT ws_total, ws_excluded, (ws_total - ws_excluded) AS excluded_count,
       gt_rows, top10_rows, overlap_rows
FROM ws_all, ws_excluded, gt_rows, top10_rows, overlap_rows;




-- COUNTS AND RATES BY GENDER

WITH gender_summary AS (
    SELECT
        gender,
        COUNT(*) FILTER (WHERE ws_finisher_flag) AS finisher_count,
        COUNT(*) FILTER (WHERE ws_dnf_flag)      AS dnf_count,
        COUNT(*) FILTER (WHERE ws_dns_flag)      AS dns_count
    FROM gt_master_table
    GROUP BY gender
)
SELECT
    gender,
    finisher_count,
    dnf_count,
    dns_count,
    (finisher_count + dnf_count) AS finisher_dnf_total,
    ROUND(
        100.0 * finisher_count / NULLIF(finisher_count + dnf_count, 0),
        1
    ) AS finisher_rate_pct,
    ROUND(
        100.0 * dnf_count / NULLIF(finisher_count + dnf_count, 0),
        1
    ) AS dnf_rate_pct,
    ROUND(
        100.0 * dns_count 
        / NULLIF(finisher_count + dnf_count + dns_count, 0),
        1
    ) AS dns_rate_pct_overall
FROM gender_summary
ORDER BY gender;

-- COUNTS AND RATES BY WS YEAR

WITH year_summary AS (
    SELECT
        ws_year,
        COUNT(*) FILTER (WHERE ws_finisher_flag) AS finisher_count,
        COUNT(*) FILTER (WHERE ws_dnf_flag)      AS dnf_count,
        COUNT(*) FILTER (WHERE ws_dns_flag)      AS dns_count
    FROM gt_master_table
    GROUP BY ws_year
)
SELECT
    ws_year,
    finisher_count,
    dnf_count,
    dns_count,
    (finisher_count + dnf_count) AS finisher_dnf_total,
    ROUND(
        100.0 * finisher_count / NULLIF(finisher_count + dnf_count, 0),
        1
    ) AS finisher_rate_pct,
    ROUND(
        100.0 * dnf_count / NULLIF(finisher_count + dnf_count, 0),
        1
    ) AS dnf_rate_pct,
    ROUND(
        100.0 * dns_count
        / NULLIF(finisher_count + dnf_count + dns_count, 0),
        1
    ) AS dns_rate_pct_overall
FROM year_summary
WHERE ws_year != 2026
ORDER BY ws_year;

-- COUNTS AND RATES BY GT RACE

WITH race_summary AS (
    SELECT
        race_name,
        COUNT(*) FILTER (WHERE ws_finisher_flag) AS finisher_count,
        COUNT(*) FILTER (WHERE ws_dnf_flag)      AS dnf_count,
        COUNT(*) FILTER (WHERE ws_dns_flag)      AS dns_count
    FROM gt_master_table
    GROUP BY race_name
)
SELECT
    race_name,
    finisher_count,
    dnf_count,
    dns_count,
    (finisher_count + dnf_count) AS finisher_dnf_total,
    ROUND(
        100.0 * finisher_count / NULLIF(finisher_count + dnf_count, 0),
        1
    ) AS finisher_rate_pct,
    ROUND(
        100.0 * dnf_count / NULLIF(finisher_count + dnf_count, 0),
        1
    ) AS dnf_rate_pct,
    ROUND(
        100.0 * dns_count
        / NULLIF(finisher_count + dnf_count + dns_count, 0),
        1
    ) AS dns_rate_pct_overall
FROM race_summary
ORDER BY race_name;

-- COUNTS AND RATES BY YEAR AND GENDER

WITH year_gender_summary AS (
    SELECT
        ws_year,
        gender,
        COUNT(*) FILTER (WHERE ws_finisher_flag) AS finisher_count,
        COUNT(*) FILTER (WHERE ws_dnf_flag)      AS dnf_count,
        COUNT(*) FILTER (WHERE ws_dns_flag)      AS dns_count
    FROM gt_master_table
    GROUP BY ws_year, gender
)
SELECT
    ws_year,
    gender,
    finisher_count,
    dnf_count,
    dns_count,
    (finisher_count + dnf_count) AS finisher_dnf_total,
    -- Rate = finisher / (finisher + dnf)
    ROUND(
        100.0 * finisher_count / NULLIF(finisher_count + dnf_count, 0),
        1
    ) AS finisher_rate_pct,
    ROUND(
        100.0 * dnf_count / NULLIF(finisher_count + dnf_count, 0),
        1
    ) AS dnf_rate_pct,
    -- DNS relative to ALL entries
    ROUND(
        100.0 * dns_count 
        / NULLIF(finisher_count + dnf_count + dns_count, 0),
        1
    ) AS dns_rate_pct_overall
FROM year_gender_summary
WHERE ws_year != 2026
ORDER BY ws_year, gender;

-- DISCOVERED TWO ATHLETES MISSING GENDER AND WS_GENDER_RANK. WILL UPDATE GENDER FOR CORRECT TOTAL PARTICIPATION
-- BUT WILL NOT RE-ASSIGN GENDER RANK.

UPDATE results_combined_master
SET gender = 'M'
WHERE race_id = '79446'
  AND year = 2021
  AND name = 'jim mccaffrey';

UPDATE results_combined_master
SET gender = 'F'
WHERE race_id = '97204'
  AND year = 2023
  AND name = 'susan henry';

SELECT *
FROM results_combined_master
WHERE race_name ILIKE 'western states%'
  AND status ILIKE 'finisher%'
  AND (gender IS NULL OR gender NOT IN ('M','F'))
ORDER BY year;

-- TOTAL WS PARTICIPATION PER YEAR

WITH ws_gender_totals AS (
    SELECT
        year AS ws_year,
        gender,
        COUNT(*)
    FROM results_combined_master
    WHERE
        race_name ILIKE 'western states%'
        AND status ILIKE 'finisher%'
    GROUP BY year, gender
)
SELECT *
FROM ws_gender_totals
ORDER BY ws_year, gender;


WITH ws_gender_totals AS (
    SELECT
        year AS ws_year,
        gender,
        COUNT(*) AS total_gender_finishers
    FROM results_combined_master
    WHERE
        race_name ILIKE 'western states%'
        AND status ILIKE 'finisher%'
        AND gender IN ('M','F')
    GROUP BY year, gender
)
SELECT
    g.ws_year,
    g.race_name AS gt_race_name,
    g.name AS athlete_name,
    g.gender,
    g.gender_rank AS gt_gender_rank,
    g.ws_gender_rank,
    t.total_gender_finishers,
	  ROUND(
        (
            (1 - ((g.ws_gender_rank - 1)::numeric / NULLIF(t.total_gender_finishers, 0))) * 100
        )::numeric,
        1
    ) AS ws_gender_percentile
FROM gt_master_table g
JOIN ws_gender_totals t
  ON g.ws_year = t.ws_year
 AND g.gender  = t.gender
WHERE g.ws_finisher_flag = TRUE
ORDER BY g.ws_year, ws_gender_percentile DESC;


WITH ws_gender_totals AS (
    SELECT
        year AS ws_year,
        gender,
        COUNT(*) AS total_gender_finishers
    FROM results_combined_master
    WHERE race_name ILIKE 'western states%'
      AND status ILIKE 'finisher%'
      AND gender IN ('M', 'F')
    GROUP BY year, gender
),
athlete_percentiles AS (
    SELECT
        g.ws_year,
        g.race_name      AS gt_race_name,
        g.name           AS athlete_name,
        g.gender,
        g.gender_rank    AS gt_gender_rank,
        g.ws_gender_rank,
        g.diff_index,                         -- course difficulty (0–100)
        t.total_gender_finishers,
        -- WS performance as percentile (0–100)
        ROUND(
            100 * (1 - ( (g.ws_gender_rank - 1)::numeric / t.total_gender_finishers )),
            1
        ) AS ws_gender_percentile
    FROM gt_master_table g
    JOIN ws_gender_totals t
      ON g.ws_year = t.ws_year
     AND g.gender  = t.gender
    WHERE g.ws_finisher_flag = TRUE
)
SELECT
    ws_year,
    gt_race_name,
    athlete_name,
    gender,
    gt_gender_rank,
    ws_gender_rank,
    diff_index,
    ws_gender_percentile,
    -- Performance Index: 70% WS perf, 30% GT course difficulty
    ROUND(
        (0.7 * ws_gender_percentile + 0.3 * diff_index)::numeric,
        1
    ) AS performance_index
FROM athlete_percentiles
ORDER BY ws_year, performance_index DESC;

SELECT corr(performance_index, ws_gender_percentile) 
FROM performance_index_table;


SELECT
    EXTRACT(YEAR FROM Race_Date) AS race_year,
    Nationality,
    COUNT(*) AS recipient_count
FROM gt_master_table
WHERE ws_year != 2026
GROUP BY race_year, Nationality
ORDER BY race_year, recipient_count DESC;


WITH gt_yearly AS (
    SELECT
        ws_year AS year,
        COUNT(*) FILTER (WHERE ws_finisher_flag) AS gt_finishers,
        COUNT(*) FILTER (WHERE ws_dnf_flag)      AS gt_dnfs
    FROM gt_master_table
    WHERE ws_year BETWEEN 2016 AND 2025
      AND ws_dns_flag = FALSE
    GROUP BY ws_year
),
top10_yearly AS (
    SELECT
        next_year AS year,
        COUNT(*) FILTER (WHERE next_status ILIKE 'Finisher') AS top10_finishers,
        COUNT(*) FILTER (WHERE next_status ILIKE 'DNF')      AS top10_dnfs
    FROM ws_top10_yoy
    WHERE next_year BETWEEN 2016 AND 2025
    GROUP BY next_year
),
ws_yearly AS (
    SELECT
        year,
        COUNT(*) FILTER (WHERE status = 'Finisher') AS ws_finishers,
        COUNT(*) FILTER (WHERE status = 'DNF')      AS ws_dnfs
    FROM results_combined_master r
    WHERE race_name ILIKE 'Western States'
      AND year BETWEEN 2016 AND 2025
      AND (name, year) NOT IN (
            SELECT name, ws_year FROM gt_master_table WHERE ws_year BETWEEN 2016 AND 2025
            UNION
            SELECT athlete_name, next_year FROM ws_top10_yoy WHERE next_year BETWEEN 2016 AND 2025
        )
    GROUP BY year
)
SELECT
    y.year,
    -- GT Recipients
    gt.gt_finishers,
    gt.gt_dnfs,
    ROUND(100.0 * gt.gt_finishers / NULLIF(gt.gt_finishers + gt.gt_dnfs, 0), 1) AS gt_finish_rate_pct,
    ROUND(100.0 * gt.gt_dnfs / NULLIF(gt.gt_finishers + gt.gt_dnfs, 0), 1) AS gt_dnf_rate_pct,
    -- WS Runners (excluding GT & Top-10)
    ws.ws_finishers,
    ws.ws_dnfs,
    ROUND(100.0 * ws.ws_finishers / NULLIF(ws.ws_finishers + ws.ws_dnfs, 0), 1) AS ws_finish_rate_pct,
    ROUND(100.0 * ws.ws_dnfs / NULLIF(ws.ws_finishers + ws.ws_dnfs, 0), 1) AS ws_dnf_rate_pct,
    -- Top-10 Returners
    t10.top10_finishers,
    t10.top10_dnfs,
    ROUND(100.0 * t10.top10_finishers / NULLIF(t10.top10_finishers + t10.top10_dnfs, 0), 1) AS top10_finish_rate_pct,
    ROUND(100.0 * t10.top10_dnfs / NULLIF(t10.top10_finishers + t10.top10_dnfs, 0), 1) AS top10_dnf_rate_pct
FROM (SELECT DISTINCT year FROM ws_yearly
      UNION SELECT DISTINCT year FROM gt_yearly
      UNION SELECT DISTINCT year FROM top10_yearly) y
LEFT JOIN gt_yearly gt ON y.year = gt.year
LEFT JOIN ws_yearly ws ON y.year = ws.year
LEFT JOIN top10_yearly t10 ON y.year = t10.year
ORDER BY y.year;


SELECT
    year,
    gender,
    COUNT(*) AS total_participants,
    COUNT(*) FILTER (WHERE status = 'Finisher') AS finishers,
    COUNT(*) FILTER (WHERE status = 'DNF') AS dnfs,
    ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'Finisher') / NULLIF(COUNT(*), 0), 1) AS finish_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'DNF') / NULLIF(COUNT(*), 0), 1) AS dnf_rate_pct
FROM results_combined_master r
WHERE race_name ILIKE 'Western States'
  AND year BETWEEN 2016 AND 2025
  AND (name, year) NOT IN (
        SELECT name, ws_year FROM gt_master_table WHERE ws_year BETWEEN 2016 AND 2025
    )
GROUP BY year, gender
ORDER BY year, gender;

