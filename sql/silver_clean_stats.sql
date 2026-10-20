-- Silver Layer Transformation: Cleans raw CSV video statistics, converts string fields to numeric/bigint types, and safely parses trending dates into Snappy-compressed Parquet.
CREATE TABLE IF NOT EXISTS yt_pipeline_silver_db.clean_raw_statistics
WITH (
  format = 'PARQUET',
  parquet_compression = 'SNAPPY',
  external_location = 's3://yt-pipeline-akshath-silver-dev/youtube/clean_raw_statistics/',
  partitioned_by = ARRAY['region']
) AS
SELECT 
  video_id,
  trending_date,
  title,
  channel_title,
  category_id,
  publish_time,
  tags,
  TRY(CAST(views AS bigint)) AS views,
  TRY(CAST(likes AS bigint)) AS likes,
  TRY(CAST(dislikes AS bigint)) AS dislikes,
  TRY(CAST(comment_count AS bigint)) AS comment_count,
  thumbnail_link,
  comments_disabled,
  ratings_disabled,
  video_error_or_removed,
  description,
  TRY(date_parse(trending_date, '%y.%d.%m')) AS trending_date_clean,
  region
FROM yt_pipeline_bronze_db.raw_statistics
WHERE video_id IS NOT NULL 
  AND video_id != 'video_id';
