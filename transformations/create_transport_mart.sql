-- Replace the project, dataset, and table names before running this query manually.
CREATE OR REPLACE TABLE `your-gcp-project-id.london_transport_dw.transport_journeys_mart`
PARTITION BY period_beginning_date
CLUSTER BY transport_type AS
WITH raw_clean AS (
    SELECT
        period_and_financial_year,
        SAFE_CAST(reporting_period AS INT64) AS reporting_period,
        SAFE_CAST(days_in_period AS INT64) AS days_in_period,
        SAFE.PARSE_DATE('%d-%b-%y', period_beginning) AS period_beginning_date,
        SAFE.PARSE_DATE('%d-%b-%y', period_ending) AS period_ending_date,
        SAFE_CAST(bus_journeys_m AS FLOAT64) AS bus_journeys_m,
        SAFE_CAST(underground_journeys_m AS FLOAT64) AS underground_journeys_m,
        SAFE_CAST(dlr_journeys_m AS FLOAT64) AS dlr_journeys_m,
        SAFE_CAST(tram_journeys_m AS FLOAT64) AS tram_journeys_m,
        SAFE_CAST(overground_journeys_m AS FLOAT64) AS overground_journeys_m,
        SAFE_CAST(london_cable_car_journeys_m AS FLOAT64) AS london_cable_car_journeys_m,
        SAFE_CAST(tfl_rail_journeys_m AS FLOAT64) AS tfl_rail_journeys_m
    FROM `your-gcp-project-id.london_transport_dw.transport_journeys_raw`
),
long_format AS (
    SELECT
        period_and_financial_year,
        reporting_period,
        days_in_period,
        period_beginning_date,
        period_ending_date,
        EXTRACT(YEAR FROM period_beginning_date) AS year,
        EXTRACT(MONTH FROM period_beginning_date) AS month,
        FORMAT_DATE('%Y-%m', period_beginning_date) AS year_month,
        'Bus' AS transport_type,
        bus_journeys_m AS journeys_m
    FROM raw_clean

    UNION ALL

    SELECT
        period_and_financial_year,
        reporting_period,
        days_in_period,
        period_beginning_date,
        period_ending_date,
        EXTRACT(YEAR FROM period_beginning_date) AS year,
        EXTRACT(MONTH FROM period_beginning_date) AS month,
        FORMAT_DATE('%Y-%m', period_beginning_date) AS year_month,
        'Underground' AS transport_type,
        underground_journeys_m AS journeys_m
    FROM raw_clean

    UNION ALL

    SELECT
        period_and_financial_year,
        reporting_period,
        days_in_period,
        period_beginning_date,
        period_ending_date,
        EXTRACT(YEAR FROM period_beginning_date) AS year,
        EXTRACT(MONTH FROM period_beginning_date) AS month,
        FORMAT_DATE('%Y-%m', period_beginning_date) AS year_month,
        'DLR' AS transport_type,
        dlr_journeys_m AS journeys_m
    FROM raw_clean

    UNION ALL

    SELECT
        period_and_financial_year,
        reporting_period,
        days_in_period,
        period_beginning_date,
        period_ending_date,
        EXTRACT(YEAR FROM period_beginning_date) AS year,
        EXTRACT(MONTH FROM period_beginning_date) AS month,
        FORMAT_DATE('%Y-%m', period_beginning_date) AS year_month,
        'Tram' AS transport_type,
        tram_journeys_m AS journeys_m
    FROM raw_clean

    UNION ALL

    SELECT
        period_and_financial_year,
        reporting_period,
        days_in_period,
        period_beginning_date,
        period_ending_date,
        EXTRACT(YEAR FROM period_beginning_date) AS year,
        EXTRACT(MONTH FROM period_beginning_date) AS month,
        FORMAT_DATE('%Y-%m', period_beginning_date) AS year_month,
        'Overground' AS transport_type,
        overground_journeys_m AS journeys_m
    FROM raw_clean

    UNION ALL

    SELECT
        period_and_financial_year,
        reporting_period,
        days_in_period,
        period_beginning_date,
        period_ending_date,
        EXTRACT(YEAR FROM period_beginning_date) AS year,
        EXTRACT(MONTH FROM period_beginning_date) AS month,
        FORMAT_DATE('%Y-%m', period_beginning_date) AS year_month,
        'London Cable Car' AS transport_type,
        london_cable_car_journeys_m AS journeys_m
    FROM raw_clean

    UNION ALL

    SELECT
        period_and_financial_year,
        reporting_period,
        days_in_period,
        period_beginning_date,
        period_ending_date,
        EXTRACT(YEAR FROM period_beginning_date) AS year,
        EXTRACT(MONTH FROM period_beginning_date) AS month,
        FORMAT_DATE('%Y-%m', period_beginning_date) AS year_month,
        'TfL Rail' AS transport_type,
        tfl_rail_journeys_m AS journeys_m
    FROM raw_clean
)
SELECT *
FROM long_format
WHERE period_beginning_date IS NOT NULL
  AND journeys_m IS NOT NULL;
