# Dashboard Layer

This module now provides two dashboard entry points:

1. BigQuery views for Looker Studio.
2. A local Streamlit dashboard in `app.py`.

## Included Files

- `app.py`: local dashboard with BigQuery mode and public CSV fallback
- `requirements.txt`: Python dependencies for the Streamlit app
- `create_dashboard_views.sql`: manual SQL for the two BigQuery views

## BigQuery Dashboard Views

### 1. Time-Series View

- view: `transport_journeys_over_time_v`
- purpose: total transport journeys over time
- recommended chart: line chart
- dimension: `period_beginning_date`
- metric: `total_journeys_m`

### 2. Category Distribution View

- view: `transport_type_distribution_v`
- purpose: total journey volume by transport type
- recommended chart: bar chart
- dimension: `transport_type`
- metric: `total_journeys_m`

The views are created by [build_dashboard_views_bigquery.yaml](../Kestra/build_dashboard_views_bigquery.yaml) or manually with [create_dashboard_views.sql](create_dashboard_views.sql).

## Run The Streamlit Dashboard

From the repository root:

```powershell
.\scripts\run_dashboard.ps1
```

The app reads from BigQuery when these environment variables are available:

- `LTA_BQ_PROJECT_ID`
- `LTA_BQ_DATASET`
- `LTA_BQ_MART_TABLE`
- `GOOGLE_APPLICATION_CREDENTIALS`

If they are not configured, the app falls back to the public TfL CSV and rebuilds the same analytical mart locally.

The repository includes `.streamlit/config.toml` so the dashboard starts headlessly on port `8501` without the first-run onboarding prompt.

## Looker Studio Setup

1. Open Looker Studio.
2. Add a BigQuery data source.
3. Connect to the dataset `london_transport_dw`.
4. Build one chart from `transport_journeys_over_time_v`.
5. Build one chart from `transport_type_distribution_v`.
6. Add titles, axis labels, and filters so the visuals are self-explanatory.
