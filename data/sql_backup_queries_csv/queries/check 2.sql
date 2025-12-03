CREATE TABLE golden_ticket_ws_results (
    gt_race_id INTEGER,
    gt_race_name VARCHAR(255),
    gt_normalized_name VARCHAR(255),
    gt_gender VARCHAR(10),
    ticket_position INTEGER,
    gt_time VARCHAR(50),
    ws_series_id INTEGER,
    ws_race_id INTEGER,
    ws_date DATE,
    ws_year INTEGER,
    ws_rank INTEGER,
    ws_status VARCHAR(50),
    nationality VARCHAR(50),
    ws_gender_rank INTEGER,
    age_category VARCHAR(50),
    ws_time VARCHAR(50),
    ws_race VARCHAR(255)
);



SELECT ws_year,
       SUM(CASE WHEN ws_status = 'DNS' THEN 1 ELSE 0 END) AS dns_count,
       SUM(CASE WHEN ws_status = 'DNF' THEN 1 ELSE 0 END) AS dnf_count,
       COUNT(*) AS total_gt_recipients
FROM golden_ticket_ws_results
GROUP BY ws_year
ORDER BY ws_year;


SELECT gt_race_name,
       COUNT(*) AS total_recipients,
       SUM(CASE WHEN ws_status = 'Finisher' THEN 1 ELSE 0 END) AS finishers,
       SUM(CASE WHEN ws_status = 'DNF' THEN 1 ELSE 0 END) AS dnfs,
       SUM(CASE WHEN ws_status = 'DNS' THEN 1 ELSE 0 END) AS dns
FROM golden_ticket_ws_results
GROUP BY gt_race_name
ORDER BY finishers DESC;

-- Correlation Between GT Time and WS Time
-- Insight: Does faster Golden Ticket race time predict faster Western States time?
SELECT ws_year,
       CORR(
         EXTRACT(EPOCH FROM gt_time::interval) / 62.137,  -- GT pace per mile
         EXTRACT(EPOCH FROM ws_time::interval) / 100       -- WS pace per mile
       ) AS corr_gt_ws_pace
FROM golden_ticket_ws_results
WHERE ws_status = 'Finisher'
GROUP BY ws_year;

CREATE TABLE course_metadata (
    series_id INTEGER,
    race_name VARCHAR(255),
    race_class VARCHAR(50),
    distance_mi DECIMAL(6,2),
    elevation_gain_ft INTEGER,
    elevation_loss_ft INTEGER,
    max_elev_ft INTEGER,
    min_elev_ft INTEGER,
    elevation_range_ft INTEGER,
    avg_grade_pct DECIMAL(5,2),
    altitude_exposure_mi DECIMAL(6,2),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    difficulty_index INTEGER
);


-- Correlation Between GT Time and WS Time
-- Insight: Does faster Golden Ticket race time predict faster Western States time?
SELECT ws_year,
       CORR(
         ((EXTRACT(EPOCH FROM gt_time::interval) / 60.0) / cm.distance_mi) *
         (1 + 0.01 * (cm.elevation_gain_ft / 1000.0) + 0.02 * (cm.difficulty_index / 100.0)),
         ((EXTRACT(EPOCH FROM ws_time::interval) / 60.0) / 100.0) *
         (1 + 0.01 * (18000 / 1000.0) + 0.02 * (100 / 100.0))
       ) AS corr_adjusted_pace
FROM golden_ticket_ws_results gtw
JOIN race_id_master rim ON gtw.gt_race_id::text = rim.race_id
JOIN course_metadata cm ON rim.series_id::text = cm.series_id::text
WHERE ws_status = 'Finisher'
GROUP BY ws_year;


SELECT race_name, COUNT(*) AS total, SUM(CASE WHEN status='DNF' THEN 1 ELSE 0 END) AS dnfs
FROM race_results
GROUP BY race_name
ORDER BY dnfs DESC;



SELECT year, gender, AVG(EXTRACT(EPOCH FROM time::interval)/3600) AS avg_hours
FROM race_results
WHERE status='Finisher' and gender!= 'X' and gender!='NULL'
GROUP BY year, gender
ORDER BY year;


SELECT nationality, AVG(EXTRACT(EPOCH FROM time::interval)/3600) AS avg_hours
FROM race_results
WHERE status='Finisher'
GROUP BY nationality
ORDER BY avg_hours;


SELECT race_id,
       nationality,
       AVG(EXTRACT(EPOCH FROM time::interval)/3600) AS avg_hours
FROM race_results
WHERE status = 'Finisher'
GROUP BY race_id, nationality
ORDER BY race_id, avg_hours;



WITH ranked AS (
    SELECT gtw.gt_race_id,
           rim.series_id,
           cm.race_class,
           gtw.ws_year,
           gtw.gt_time,
           gtw.ws_time,
           ROW_NUMBER() OVER (PARTITION BY gtw.gt_race_id ORDER BY gtw.gt_time ASC) AS rank
    FROM golden_ticket_ws_results gtw
    JOIN race_id_master rim ON gtw.gt_race_id::text = rim.race_id
    JOIN course_metadata cm ON rim.series_id::text = cm.series_id::text
    WHERE ws_status = 'Finisher'
)
SELECT *
FROM ranked
WHERE rank <= 10;



SELECT series_id, race_name, year, COUNT(*) AS participants
FROM race_results
WHERE status IN ('Finisher', 'DNF')
	AND race_dist = '100K'
GROUP BY series_id, year, race_name
ORDER BY series_id, year;


SELECT year, AVG(EXTRACT(EPOCH FROM time::interval)/3600) AS avg_hours
FROM race_results
WHERE series_id = 623  AND status = 'Finisher'
GROUP BY year
ORDER BY year;


WITH winners AS (
    SELECT race_id, gender, MIN(time) AS winner_time
    FROM race_results
    WHERE series_id = 10254 AND status = 'Finisher'
    GROUP BY race_id, gender
)
SELECT w1.race_id,
       EXTRACT(EPOCH FROM w1.winner_time::interval - w2.winner_time::interval)/3600 AS gap_hours
FROM winners w1
JOIN winners w2 ON w1.race_id = w2.race_id AND w1.gender = 'M' AND w2.gender = 'F'
ORDER BY w1.race_id;

