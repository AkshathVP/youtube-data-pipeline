# Serverless YouTube Data Pipeline (AWS Medallion Architecture)

A serverless, automated end-to-end data pipeline built on AWS that ingests, transforms, catalogings, and aggregates YouTube trending statistics across multiple global regions.

---

## 🏗️ Architecture

The pipeline follows the **Medallion Data Lake Pattern** (Bronze → Silver → Gold):

```mermaid
flowchart TD
    A["Raw Ingestion Data\n(CSV / JSON)"] --> B["Bronze S3 Bucket\n(Raw Data Staging)"]
    
    B --> C["AWS Lambda\n(JSON Parsing & Parquet)"]
    B --> D["Amazon Athena CTAS\n(Data Cleaning & Type Casting)"]
    
    C --> E["Silver S3 Bucket\n(Clean Partitioned Parquet)"]
    D --> E
    
    E --> F["Amazon Athena CTAS\n(SQL Aggregations & Joins)"]
    
    F --> G["Gold S3 Bucket\n(Analytics-Ready Business Data)"]

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
