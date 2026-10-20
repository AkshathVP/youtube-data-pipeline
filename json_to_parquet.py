import json
import os
import tempfile
import logging
import urllib.parse
import boto3
import pandas as pd

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')

def extract_region_from_key(key):
    """Safely extract region code from filename (e.g. youtube/reference_data/US_category_id.json -> us)"""
    filename = os.path.basename(key)
    if '_' in filename:
        return filename.split('_')[0].lower()
    return 'us'

def process_single_s3_record(bucket, key):
    """Processes a single JSON reference file and writes Parquet to S3 Silver layer."""
    region = extract_region_from_key(key)
    logger.info(f"Processing reference JSON for region: '{region}' from s3://{bucket}/{key}")

    response = s3_client.get_object(Bucket=bucket, Key=key)
    content = json.loads(response['Body'].read().decode('utf-8'))

    categories = []
    for item in content.get('items', []):
        try:
            snippet = item.get('snippet', {})
            categories.append({
                'category_id': int(item['id']),
                'category_title': str(snippet.get('title', 'Unknown')),
                'assignable': bool(snippet.get('assignable', False)),
                'channel_id': str(snippet.get('channelId', '')),
                'region': region
            })
        except (KeyError, ValueError) as e:
            logger.warning(f"Skipping malformed category item in {key}: {e}")
            continue

    if not categories:
        logger.warning(f"No valid category records found in {key}")
        return None

    df = pd.DataFrame(categories)

    target_bucket = os.environ.get('SILVER_BUCKET', 'yt-pipeline-akshath-silver-dev')
    target_key = f"youtube/clean_reference_data/region={region}/category_data.parquet"

    with tempfile.NamedTemporaryFile(suffix='.parquet', delete=False) as tmp_file:
        temp_parquet_path = tmp_file.name

    try:
        df.to_parquet(temp_parquet_path, engine='pyarrow', index=False, compression='snappy')
        s3_client.upload_file(temp_parquet_path, target_bucket, target_key)
        logger.info(f"Successfully uploaded clean Parquet to s3://{target_bucket}/{target_key}")
    finally:
        if os.path.exists(temp_parquet_path):
            os.remove(temp_parquet_path)

    return target_key

def lambda_handler(event, context):
    """AWS Lambda entry point handling both S3 event triggers and direct Step Functions calls."""
    logger.info(f"Received event: {json.dumps(event)}")
    processed_keys = []

    if 'Records' in event:
        for record in event['Records']:
            bucket = record['s3']['bucket']['name']
            key = urllib.parse.unquote_plus(record['s3']['object']['key'])
            result = process_single_s3_record(bucket, key)
            if result:
                processed_keys.append(result)
    else:
        bucket = event.get('bucket', os.environ.get('BRONZE_BUCKET', 'yt-pipeline-akshath-bronze-dev'))
        key = event.get('key', 'youtube/reference_data/US_category_id.json')
        result = process_single_s3_record(bucket, key)
        if result:
            processed_keys.append(result)

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'JSON reference data successfully transformed to Parquet',
            'processed_files': processed_keys
        })
    }
