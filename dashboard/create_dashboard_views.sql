-- Time-series dashboard source
CREATE OR REPLACE VIEW `your-gcp-project-id.london_transport_dw.transport_journeys_over_time_v` AS
SELECT
    period_beginning_date,
    year_month,
    SUM(journeys_m) AS total_journeys_m
FROM `your-gcp-project-id.london_transport_dw.transport_journeys_mart`
GROUP BY period_beginning_date, year_month
ORDER BY period_beginning_date;

-- Categorical dashboard source
CREATE OR REPLACE VIEW `your-gcp-project-id.london_transport_dw.transport_type_distribution_v` AS
SELECT
    transport_type,
    SUM(journeys_m) AS total_journeys_m
FROM `your-gcp-project-id.london_transport_dw.transport_journeys_mart`
GROUP BY transport_type
ORDER BY total_journeys_m DESC;
