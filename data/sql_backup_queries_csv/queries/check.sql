
WITH RankedResults AS (
    SELECT
        race_id,
        race_name,
        gender,
        name,
        rank,
        time,
        ROW_NUMBER() OVER (PARTITION BY race_id, gender ORDER BY rank ASC) AS gender_rank
    FROM race_results
    WHERE status = 'Finisher'
)
SELECT *
FROM race_results
WHERE gender_rank::integer <= 10
	AND series_id = 17002
ORDER BY
	race_id, gender, gender_rank::integer;

TRUNCATE TABLE race_results;

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
    FROM race_results
    WHERE status = 'Finisher'
),
TopFinishers AS (
    SELECT *
    FROM RankedResults
    WHERE gender_rank::integer <= 10
      AND series_id = 17002
      AND year = 2024
),
NextYearResults AS (
    SELECT *
    FROM race_results
    WHERE year = 2025
	AND series_id = 17002
)
SELECT
    tf.name AS runner_name,
    tf.gender AS original_gender,
    tf.race_name AS original_race,
	tf.year AS original_year,
    tf.gender_rank::integer AS original_rank,
    tf.time AS original_time,
    ny.year AS next_year,
    ny.gender_rank::integer AS next_rank,
    ny.time AS next_time,
    ny.status AS next_status
FROM TopFinishers tf
LEFT JOIN NextYearResults ny
  ON LOWER(TRIM(tf.name)) = LOWER(TRIM(ny.name))
ORDER BY
	tf.gender, tf.gender_rank::integer;


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
    FROM race_results
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
    FROM race_results
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
WHERE tf.year >= 2022
ORDER BY
    tf.year, tf.gender, tf.gender_rank;
