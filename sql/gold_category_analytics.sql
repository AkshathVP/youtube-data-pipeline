-- Gold Layer Aggregation: Deduplicates daily observations per video ID to compute unique video statistics per region and category.
CREATE TABLE IF NOT EXISTS yt_pipeline_gold_db.trending_category_analytics_v2
WITH (
  format = 'PARQUET',
  parquet_compression = 'SNAPPY',
  external_location = 's3://yt-pipeline-akshath-gold-dev/youtube/trending_category_analytics_v2/'
) AS
WITH deduplicated_statistics AS (
  SELECT 
    region,
    video_id,
    category_id,
    MAX(views) AS max_views,
    MAX(likes) AS max_likes,
    MAX(comment_count) AS max_comments
  FROM yt_pipeline_silver_db.clean_raw_statistics
  WHERE video_id IS NOT NULL
  GROUP BY region, video_id, category_id
)
SELECT 
  s.region,
  COALESCE(r.category_title, 'Unknown') AS category_title,
  COUNT(DISTINCT s.video_id) AS total_unique_trending_videos,
  SUM(s.max_views) AS total_views,
  SUM(s.max_likes) AS total_likes,
  SUM(s.max_comments) AS total_comments,
  ROUND(AVG(s.max_views), 0) AS avg_views_per_video,
  ROUND((SUM(s.max_likes + s.max_comments) * 100.0) / NULLIF(SUM(s.max_views), 0), 2) AS engagement_rate_pct
FROM deduplicated_statistics s
LEFT JOIN (
  SELECT DISTINCT category_id, region, category_title 
  FROM yt_pipeline_silver_db.clean_reference_data
) r ON s.category_id = r.category_id AND s.region = r.region
GROUP BY s.region, COALESCE(r.category_title, 'Unknown');
