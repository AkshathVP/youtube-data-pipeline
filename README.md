# Serverless YouTube Data Pipeline (AWS Medallion Architecture)

A serverless, automated end-to-end data pipeline built on AWS that ingests, transforms, catalogings, and aggregates YouTube trending statistics across multiple global regions.

---

## 🏗️ Architecture

The pipeline follows the **Medallion Data Lake Pattern** (Bronze → Silver → Gold):
```text
[ Raw Data (CSV / JSON) ]
|
▼
┌──────────────────────────────┐
│  Bronze S3   | <-- Raw Data Staging
└──────────────────────────────┘
|
├── AWS Lambda (Python / AWSSDKPandas) --> JSON flattening & Parquet conversion
├── AWS Athena CTAS Queries           --> Data cleaning, Type casting, MSCK REPAIR
▼
┌──────────────────────────────┐
│  Silver S3   | <-- Cleaned Partitioned Parquet Data
└──────────────────────────────┘
|
├── Athena CTAS / SQL Aggregations   --> Cross-table JOINs & Metrics
▼
┌──────────────────────────────┐
│  Gold S3     | <-- Analytics-Ready Business Data
└──────────────────────────────┘
```


## ⚡ Automation & Orchestration

The workflow is orchestrated sequentially using **AWS Step Functions** (`yt-pipeline-orchestrator`):
1. **Lambda Task:** Extracts category IDs and titles from raw reference JSON and writes Snappy Parquet to the Silver layer.
2. **Silver Statistics Task:** Executes a synchronous Athena CTAS query to parse raw statistics into partitioned Parquet tables.
3. **Gold Aggregation Task:** Joins statistics with reference data, outputting total views, engagement rates, and video counts per category and region.

---

## 📊 Performance & Optimization Results

| Metric | Raw Ingestion (CSV/JSON) | Optimized Layer (Parquet) |
| :--- | :--- | :--- |
| **Format** | Uncompressed CSV / JSON | Snappy-compressed Columnar Parquet |
| **Data Scanned per Query** | ~30 MB – 250 MB | **1.24 KB** (> 99% cost reduction) |
| **Query Execution Time** | ~4.0s – 8.0s | **336 ms** |

---

## 🛠️ Stack & Technologies

* **Cloud Services:** AWS S3, AWS Glue Data Catalog, Amazon Athena, AWS Lambda, AWS Step Functions
* **Languages & Libraries:** Python 3.11, SQL (ANSI/Athena), AWSSDKPandas, Amazon States Language (ASL)
* **CLI / Scripting:** PowerShell, AWS CLI
