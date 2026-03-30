# Kestra Orchestration

This module contains the batch orchestration layer for London Transport Analytics.

## What This Module Does

The Kestra flows implement the end-to-end pipeline:

1. Download the official TfL CSV dataset.
2. Upload the raw file to GCS.
3. Load the latest raw file into BigQuery.
4. Build the partitioned mart table.
5. Create dashboard-ready BigQuery views.

## Files

- `docker-compose.yml`: local Kestra environment
- `set_kv.yaml`: initializes project KV values
- `data_load_gcs.yaml`: downloads the source file and uploads it to GCS
- `gcs_to_bigquery_raw.yaml`: loads the latest raw CSV into BigQuery
- `build_mart_bigquery.yaml`: creates the analytical mart table
- `build_dashboard_views_bigquery.yaml`: creates the two dashboard views
- `end_to_end_pipeline.yaml`: orchestrates the full DAG

## Prerequisites

- Docker Desktop
- a GCP project
- a GCS bucket and BigQuery dataset created by Terraform
- a GCP service account with access to GCS and BigQuery

## Local Startup

```powershell
cd Kestra
docker compose up
```

Open `http://localhost:8080`.

Local development uses Basic Auth, and the one-shot `flow-bootstrap` service imports the flow YAML files through the Kestra API after the server is healthy.

Default local credentials:

- Username: `admin@kestra.io`
- Password: `Kestra123`

Manual import is no longer required for local development.

If you previously started Kestra with a different auth setup, reset the local state with `docker compose down -v` before starting again.

## Required Secret and KV Values

For local OSS Kestra, generate the secret env file:

```bash
./scripts/configure_kestra_secret.sh
```

This creates `Kestra/.env` with the local secrets required by the OSS container setup. Kestra exposes them as `secret('GCP_SERVICE_ACCOUNT')` for plugin tasks and `secret('GCP_SERVICE_ACCOUNT_B64')` for the Python BigQuery tasks.

Initialize these KV entries by running `set_kv`:

- `GCP_PROJECT_ID`
- `GCP_LOCATION`
- `GCP_BUCKET_NAME`
- `DATASET_URL`
- `BQ_DATASET_NAME`
- `BQ_RAW_TABLE_NAME`
- `BQ_MART_TABLE_NAME`
- `BQ_DASHBOARD_TIME_VIEW_NAME`
- `BQ_DASHBOARD_CATEGORY_VIEW_NAME`

The underlying secret value is the full JSON payload of the service account key, base64-encoded for local Docker Compose usage.

## Flow Summary

`data_load_gcs.yaml`

1. Downloads the TfL CSV using Python.
2. Validates that the file is not empty.
3. Uploads the file to the raw GCS landing path.
4. Removes temporary execution files.

`gcs_to_bigquery_raw.yaml`

1. Lists raw files in GCS.
2. Picks the latest CSV.
3. Loads the file into the raw BigQuery table with an explicit schema.

`build_mart_bigquery.yaml`

1. Reads the raw table.
2. Parses dates and metrics.
3. Reshapes wide columns into a long format.
4. Creates a partitioned and clustered mart.

`build_dashboard_views_bigquery.yaml`

1. Reads the mart table.
2. Builds the temporal dashboard view.
3. Builds the categorical dashboard view.

`end_to_end_pipeline.yaml`

Runs the four flows above in sequence as subflows.

## Target GCS Layout

```text
gs://<bucket>/raw/tfl_journeys_by_type/extract_date=YYYY-MM-DD/tfl_journeys_by_type_YYYY-MM-DD.csv
```
