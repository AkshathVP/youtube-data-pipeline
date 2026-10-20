-- Gold Layer Aggregation: Joins cleaned Silver statistics with reference category titles to compute aggregated metrics per region and category.
CREATE TABLE IF NOT EXISTS yt_pipeline_gold_db.trending_category_analytics_v2
WITH (
  format = 'PARQUET',
  parquet_compression = 'SNAPPY',
  external_location = 's3://yt-pipeline-akshath-gold-dev/youtube/trending_category_analytics_v2/'
) AS
SELECT 
  s.region,
  COALESCE(r.category_title, 'Unknown') AS category_title,
  COUNT(DISTINCT s.video_id) AS total_trending_videos,
  SUM(s.views) AS total_views,
  SUM(s.likes) AS total_likes,
  SUM(s.comment_count) AS total_comments,
  ROUND(AVG(s.views), 0) AS avg_views_per_video,
  ROUND((SUM(s.likes + s.comment_count) * 100.0) / NULLIF(SUM(s.views), 0), 2) AS engagement_rate_pct
FROM yt_pipeline_silver_db.clean_raw_statistics s
LEFT JOIN yt_pipeline_silver_db.clean_reference_data r
  ON s.category_id = r.category_id AND s.region = r.region
GROUP BY s.region, COALESCE(r.category_title, 'Unknown');
