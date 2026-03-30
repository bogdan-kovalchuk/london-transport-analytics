# Transformations Layer

This module documents the analytical mart used by the dashboard layer.

## Scope

The transformation step builds `transport_journeys_mart` from the raw BigQuery table.

It performs:

- date parsing from raw strings
- numeric casting for journey metrics
- wide-to-long reshaping across transport modes
- partitioning and clustering for dashboard-friendly queries

## Target Mart Table

- dataset: `london_transport_dw`
- table: `transport_journeys_mart`

## Output Grain

One row per:

- reporting period
- transport type

Key fields:

- `period_and_financial_year`
- `reporting_period`
- `days_in_period`
- `period_beginning_date`
- `period_ending_date`
- `year`
- `month`
- `year_month`
- `transport_type`
- `journeys_m`

## Storage Optimization

The mart is:

- partitioned by `period_beginning_date`
- clustered by `transport_type`

That matches the main access patterns used in the dashboard:

- temporal trend analysis
- category distribution by transport mode

## Files

- [build_mart_bigquery.yaml](../Kestra/build_mart_bigquery.yaml): orchestrated mart build
- [create_transport_mart.sql](create_transport_mart.sql): manual SQL version of the same transformation
