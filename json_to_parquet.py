import json
import os
import boto3
import pandas as pd

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    silver_bucket = os.environ.get('SILVER_BUCKET')
    
    # 1. Parse bucket and key from S3 Event Trigger or run manually for historical files
    if 'Records' in event:
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        source_key = event['Records'][0]['s3']['object']['key']
    else:
        # Fallback default for manual test invocations
        source_bucket = f"{silver_bucket.replace('-silver-', '-bronze-')}"
        source_key = "youtube/reference_data/US_category_id.json"

    print(f"Processing JSON from s3://{source_bucket}/{source_key}")

    # 2. Fetch raw JSON file from Bronze S3
    response = s3_client.get_object(Bucket=source_bucket, Key=source_key)
    content = json.loads(response['Body'].read().decode('utf-8'))

    # 3. Normalize nested JSON structure
    categories = []
    for item in content.get('items', []):
        categories.append({
            'category_id': int(item['id']),
            'category_title': item['snippet']['title'],
            'assignable': item['snippet']['assignable'],
            'channel_id': item['snippet']['channelId']
        })

    df = pd.DataFrame(categories)

    # 4. Write converted Parquet directly to Silver S3
    region_code = os.path.basename(source_key).split('_')[0].lower()
    output_key = f"youtube/clean_reference_data/region={region_code}/category_data.parquet"
    
    local_path = "/tmp/temp_data.parquet"
    df.to_parquet(local_path, index=False)
    
    s3_client.upload_file(local_path, silver_bucket, output_key)
    print(f"Successfully uploaded cleaned Parquet to s3://{silver_bucket}/{output_key}")

    return {
        'statusCode': 200,
        'body': json.dumps({'output_key': output_key, 'rows_processed': len(df)})
    }