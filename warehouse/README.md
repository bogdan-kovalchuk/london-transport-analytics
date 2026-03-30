# Warehouse Layer

This module documents the raw warehouse step for London Transport Analytics.

## Scope

The warehouse stage loads the latest raw CSV file from GCS into a BigQuery raw table.

This layer stays intentionally close to the source:

- original source columns are preserved
- values are loaded as strings
- parsing and reshaping are deferred to the transformation layer

## Raw Table

- dataset: `london_transport_dw`
- table: `transport_journeys_raw`

## Raw Schema

The raw table includes:

- `period_and_financial_year`
- `reporting_period`
- `days_in_period`
- `period_beginning`
- `period_ending`
- `bus_journeys_m`
- `underground_journeys_m`
- `dlr_journeys_m`
- `tram_journeys_m`
- `overground_journeys_m`
- `london_cable_car_journeys_m`
- `tfl_rail_journeys_m`

## Loading Strategy

The raw load is orchestrated through `Kestra/gcs_to_bigquery_raw.yaml`:

1. Find the latest raw CSV in the GCS landing area.
2. Load it into BigQuery with an explicit schema.
3. Replace the current raw snapshot with the latest file.

## Downstream Step

The transformation stage that builds the analytical mart is documented in [transformations/README.md](../transformations/README.md).
