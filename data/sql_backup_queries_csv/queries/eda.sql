WITH base AS (
    SELECT
		"race_name",
        "gender",
        "ws_year",
        "ws_gender_rank",
        "days_to_ws",
        "ws_finisher_flag",
        MAX("ws_gender_rank") OVER (PARTITION BY "ws_year", "gender") AS max_gender_rank
    FROM gt_master_table
)
SELECT
    CASE 
        WHEN "days_to_ws" < 80 THEN '< 80 days'
        WHEN "days_to_ws" BETWEEN 80 AND 119 THEN '80–119'
        WHEN "days_to_ws" BETWEEN 120 AND 179 THEN '120–179'
        ELSE '180+'
    END AS recovery_window,
    COUNT(*) AS num_athletes,
    AVG("ws_gender_rank") AS avg_ws_gender_rank,
    AVG(
        1.0 - (("ws_gender_rank" - 1)::float / NULLIF(max_gender_rank - 1, 0))
    ) AS avg_ws_percentile
FROM base
WHERE "ws_finisher_flag" = TRUE
GROUP BY recovery_window
ORDER BY recovery_window;

SELECT *
FROM gt_master_table;


SELECT
    SUM(CASE WHEN "ws_gender_rank" <= 3 THEN 1 ELSE 0 END) AS top3,
    SUM(CASE WHEN "ws_gender_rank" <= 5 THEN 1 ELSE 0 END) AS top5,
    SUM(CASE WHEN "ws_gender_rank" <= 10 THEN 1 ELSE 0 END) AS top10,
    SUM(CASE WHEN "ws_gender_rank" <= 20 THEN 1 ELSE 0 END) AS top20,
    COUNT(*) AS total_gt_recipients
FROM gt_master_table
WHERE ws_dns_flag = FALSE;


SELECT 
    "gender",
    SUM(CASE WHEN "ws_gender_rank" <= 10 THEN 1 ELSE 0 END) AS top10_finishes,
    COUNT(*) AS total_gt,
    ROUND(100.0 * SUM(CASE WHEN "ws_gender_rank" <= 10 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_top10
FROM gt_master_table
WHERE ws_dns_flag = FALSE
GROUP BY "gender"
ORDER BY "gender";


SELECT 
    g.name                      AS athlete_name,
    g.nationality,
    -- GT race info
    g.race_name                 AS gt_race_name,
    EXTRACT(YEAR FROM g.race_date) AS gt_race_year, 
    -- First WS Top 10 year (from both tables, should match)
    EXTRACT(YEAR FROM g.ws_date) AS ws_year_first_top10,
    w.original_year             AS original_year_ws,
    w.original_gender_rank      AS first_top10_rank, 
    -- Return WS Top 10 year
    w.next_year                 AS ws_return_year,
    w.next_gender_rank          AS return_top10_rank,
    -- How much they improved or dropped in rank
    (w.original_gender_rank - w.next_gender_rank) AS rank_change
FROM gt_master_table g
JOIN ws_top10_yoy w
      ON g.name = w.athlete_name
     AND EXTRACT(YEAR FROM g.ws_date) = w.original_year
WHERE 
      w.original_gender_rank <= 10          -- first year Top 10
  AND w.next_year = w.original_year + 1     -- came back the very next WS
  AND w.next_gender_rank <= 10              -- next year also Top 10
  AND g.ws_finisher_flag = TRUE             -- this WS entry was actually finished
  AND g.ticket_position IS NOT NULL         -- they entered that WS as a GT recipient
ORDER BY 
    athlete_name,
    ws_return_year;


WITH labeled_pairs AS (
    SELECT
        w.athlete_name,
        w.original_year,
        w.original_gender_rank,
        w.next_year,
        w.next_gender_rank,
        (w.original_gender_rank - w.next_gender_rank) AS rank_change,
        CASE 
            WHEN EXISTS (
                SELECT 1
                FROM gt_master_table g
                WHERE g.name = w.athlete_name
                  AND EXTRACT(YEAR FROM g.ws_date) = w.original_year
                  AND g.ticket_position IS NOT NULL   -- GT entry
                  AND g.ws_finisher_flag = TRUE       -- actually finished
            )
            THEN 'gt_entry'
            ELSE 'non_gt_entry'
        END AS cohort
    FROM ws_top10_yoy w
    WHERE 
          w.original_gender_rank <= 10
      	AND w.next_year = w.original_year + 1
      -- AND w.next_gender_rank <= 10
)
SELECT
    cohort,
    AVG(rank_change) AS avg_rank_change,
    COUNT(*)         AS n_pairs
FROM labeled_pairs
GROUP BY cohort;



WITH labeled_pairs AS (
    SELECT
        w.athlete_name,
        w.original_year,
        w.original_gender_rank,
        w.next_year,
        w.next_gender_rank,
        (w.original_gender_rank - w.next_gender_rank) AS rank_change,
        CASE 
            WHEN EXISTS (
                SELECT 1
                FROM gt_master_table g
                WHERE g.name = w.athlete_name
                  AND EXTRACT(YEAR FROM g.ws_date) = w.original_year
                  AND g.ticket_position IS NOT NULL   -- GT entry
                  AND g.ws_finisher_flag = TRUE       -- actually finished
            )
            THEN 'gt_entry'
            ELSE 'non_gt_entry'
        END AS cohort
    FROM ws_top10_yoy w
    WHERE 
          w.original_gender_rank <= 10
      	AND w.next_year = w.original_year + 1
      -- AND w.next_gender_rank <= 10
)
SELECT
    *
FROM labeled_pairs
WHERE cohort = 'gt_entry'
ORDER BY rank_change DESC;


WITH gt_top10_pairs AS (
    SELECT 
        g.name AS athlete_name,
        g.nationality,
        g.race_name AS gt_race_name,
        EXTRACT(YEAR FROM g.race_date) AS gt_race_year,
        EXTRACT(YEAR FROM g.ws_date) AS ws_year_first_top10,
        w.original_year,
        w.original_gender_rank,
        w.next_year,
        w.next_gender_rank
    FROM gt_master_table g
    JOIN ws_top10_yoy w
          ON g.name = w.athlete_name
         AND EXTRACT(YEAR FROM g.ws_date) = w.original_year
    WHERE 
          w.original_gender_rank <= 10
      AND w.next_year = w.original_year + 1
      AND w.next_gender_rank <= 10
      AND g.ws_finisher_flag = TRUE
      AND g.ticket_position IS NOT NULL
),
gt_triple_top10 AS (
    SELECT
        p.athlete_name,
        p.nationality,
        p.gt_race_name,
        p.gt_race_year,
        p.original_year AS year_1,
        p.original_gender_rank AS rank_year_1,
        p.next_year AS year_2,
        p.next_gender_rank AS rank_year_2,
        w2.next_year AS year_3,
        w2.next_gender_rank AS rank_year_3
    FROM gt_top10_pairs p
    JOIN ws_top10_yoy w2
          ON w2.athlete_name = p.athlete_name
         AND w2.original_year = p.next_year       -- year 2 in first pair = original_year for second pair
         AND w2.next_year = p.next_year + 1       -- year 3 = year 2 + 1
         AND w2.next_gender_rank <= 10            -- Top 10 again in year 3
)
SELECT
    *
FROM gt_triple_top10
ORDER BY athlete_name, year_1;

-- Gender Avg/Min/Max top 10 WS finish time by year

SELECT 
    year,
    gender,
    TO_CHAR( ((AVG(time) * 86400)::int || ' second')::interval, 'HH24:MI:SS' ) 
        AS avg_top10_time,
    TO_CHAR( ((MIN(time) * 86400)::int || ' second')::interval, 'HH24:MI:SS' ) 
        AS best_time,
    TO_CHAR( ((MAX(time) * 86400)::int || ' second')::interval, 'HH24:MI:SS' ) 
        AS slowest_top10_time,
    COUNT(*) AS num_finishers
FROM results_combined_master
WHERE gender_rank <= 10
  AND year BETWEEN 2016 AND 2025
  AND time IS NOT NULL
  AND series_id = '17002'
GROUP BY year, gender
ORDER BY year, gender;

-- Avg top 10 WS finish time by year (not by gender)
 
SELECT 
    year,
     TO_CHAR( ((AVG(time) * 86400)::int || ' second')::interval, 'HH24:MI:SS' )  AS avg_top10_finish_sec
FROM results_combined_master
WHERE gender_rank <= 10
  AND year BETWEEN 2016 AND 2025
  AND time IS NOT NULL
  AND series_id = '17002'
GROUP BY year
ORDER BY year;

-- Top 10 Median Finish Time WS by Gender

SELECT 
    year,
    gender,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY time) 
        AS median_finish_frac_day,
    -- Convert to seconds
    (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY time) * 86400) 
        AS median_finish_seconds,
    -- Convert to HH:MM:SS
    TO_CHAR(
        (
            (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY time) * 86400)::int 
            || ' second'
        )::interval,
        'HH24:MI:SS'
    ) AS median_finish_time
FROM results_combined_master
WHERE gender_rank <= 10
  AND time IS NOT NULL
  AND series_id = '17002'
  AND year BETWEEN 2016 AND 2025
GROUP BY year, gender
ORDER BY year, gender;

-- WS Top 10 finish time spread 1st to 10th

SELECT 
    year,
    gender,
    MIN(time) * 86400 AS first_place_seconds,
    MAX(time) * 86400 AS tenth_place_seconds,
    (MAX(time) - MIN(time)) * 86400 
        AS spread_seconds,
    TO_CHAR(
        (
            ((MAX(time) - MIN(time)) * 86400)::int
            || ' second'
        )::interval,
        'HH24:MI:SS'
    ) AS spread_time
FROM results_combined_master
WHERE gender_rank <= 10
  AND time IS NOT NULL
  AND series_id = '17002'
  AND year BETWEEN 2016 AND 2025
GROUP BY year, gender
ORDER BY year, gender;


WITH top10_metrics AS (
    SELECT 
        year,
        gender,
        -- Median Top-10 finish time (fraction of day)
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY time)
            AS median_top10_frac,
        -- As seconds
        (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY time) * 86400)
            AS median_top10_seconds,
        TO_CHAR(
            (
                (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY time) * 86400)::int
                || ' second'
            )::interval,
            'HH24:MI:SS'
        ) AS median_top10_time,
		 MIN(time) * 86400 AS best_top10_seconds,
        TO_CHAR(
            (
                (MIN(time) * 86400)::int || ' second'
            )::interval,
            'HH24:MI:SS'
        ) AS best_top10_time,
        -- 1st–10th spread in seconds
        (MAX(time) - MIN(time)) * 86400
            AS spread_top10_seconds,
        TO_CHAR(
            (
                ((MAX(time) - MIN(time)) * 86400)::int
                || ' second'
            )::interval,
            'HH24:MI:SS'
        ) AS spread_top10_time
    FROM results_combined_master
    WHERE gender_rank <= 10
      AND time IS NOT NULL
      AND series_id = '17002'         -- Western States
      AND year BETWEEN 2016 AND 2025
    GROUP BY year, gender
),
gt_metrics AS (
    SELECT
        ws_year,
        gender,
        -- Median finish time for *all GT recipients* (any rank, must finish)
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ws_finish_time)
            AS median_gt_frac,
        (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ws_finish_time) * 86400)
            AS median_gt_seconds,
        TO_CHAR(
            (
                (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ws_finish_time) * 86400)::int
                || ' second'
            )::interval,
            'HH24:MI:SS'
        ) AS median_gt_time,
        -- Fastest & slowest GT recipient finish times (seconds)
        MIN(ws_finish_time) * 86400 AS best_gt_seconds,
        TO_CHAR(
            (
                (MIN(ws_finish_time) * 86400)::int || ' second'
            )::interval,
            'HH24:MI:SS'
        ) AS best_gt_time,
        MAX(ws_finish_time) * 86400 AS worst_gt_seconds,
        TO_CHAR(
            (
                (MAX(ws_finish_time) * 86400)::int || ' second'
            )::interval,
            'HH24:MI:SS'
        ) AS worst_gt_time,
        COUNT(*) AS gt_finishers
    FROM gt_master_table
    WHERE ticket_position IS NOT NULL      -- GT entry
      AND ws_finisher_flag = TRUE         -- must have finished
      AND ws_finish_time IS NOT NULL
    GROUP BY ws_year, gender
)
SELECT
    t.year,
    t.gender,
    -- Top-10 metrics (seconds + formatted)
    t.median_top10_seconds,
    t.median_top10_time,
    t.spread_top10_seconds,
    t.spread_top10_time,
    -- GT recipient metrics (all finishers)
    g.median_gt_seconds,
    g.median_gt_time,
    g.best_gt_seconds,
    g.best_gt_time,
    g.worst_gt_seconds,
    g.worst_gt_time,
    g.gt_finishers,
    -- Difference: how far off GT median is from Top-10 median
    (g.median_gt_seconds - t.median_top10_seconds) AS gt_minus_top10_seconds,
    TO_CHAR(
        (
            (g.median_gt_seconds - t.median_top10_seconds)::int || ' second'
        )::interval,
        'HH24:MI:SS'
    ) AS gt_minus_top10_time
FROM top10_metrics t
LEFT JOIN gt_metrics g
       ON t.year = g.ws_year
      AND t.gender = g.gender
ORDER BY t.year, t.gender;


SELECT
    ws_year,
    gender,
    AVG(ws_gender_rank) AS avg_gt_gender_rank,
    MIN(ws_gender_rank) AS best_gt_gender_rank,
    MAX(ws_gender_rank) AS worst_gt_gender_rank,
    COUNT(*) AS num_gt_finishers
FROM gt_master_table
WHERE ticket_position IS NOT NULL        -- GT entry
  AND ws_finisher_flag = TRUE           -- must have finished
  AND ws_gender_rank IS NOT NULL
GROUP BY ws_year, gender
ORDER BY ws_year, gender;0


SELECT *
FROM results_combined_master
WHERE series_id = '17002'
	AND year BETWEEN 2016 AND 2025
ORDER BY
	year, rank;
