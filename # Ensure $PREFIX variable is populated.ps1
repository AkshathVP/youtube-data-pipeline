# Ensure $PREFIX variable is populated
if (-not $PREFIX) { $PREFIX = "yt-pipeline-akshath" }

# 1. Upload CSV files with Hive-style region partitioning
Get-ChildItem -Path "data\raw_csv\*.csv" | ForEach-Object {
    $fileName = $_.Name
    # Extract 2-letter region code (e.g., CAvideos.csv -> ca)
    $regionCode = $fileName.Substring(0, 2).ToLower()
    $s3Path = "s3://$PREFIX-bronze-dev/youtube/raw_statistics/region=$regionCode/$fileName"
    Write-Host "Uploading $fileName to $s3Path..."
    aws s3 cp $_.FullName $s3Path
}

# 2. Upload JSON category reference files
Get-ChildItem -Path "data\raw_json\*.json" | ForEach-Object {
    $fileName = $_.Name
    $s3Path = "s3://$PREFIX-bronze-dev/youtube/reference_data/$fileName"
    Write-Host "Uploading $fileName to $s3Path..."
    aws s3 cp $_.FullName $s3Path
}