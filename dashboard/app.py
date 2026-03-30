from __future__ import annotations

import io
import os
import urllib.request

import pandas as pd
import plotly.express as px
import streamlit as st

DATASET_URL = (
    "https://data.london.gov.uk/download/ep8ow/"
    "06a805f6-77c6-481a-8b08-ddef56afffdd/tfl-journeys-type.csv"
)

SOURCE_COLUMNS = {
    "Period and Financial year": "period_and_financial_year",
    "Reporting Period": "reporting_period",
    "Days in period": "days_in_period",
    "Period beginning": "period_beginning",
    "Period ending": "period_ending",
    "Bus journeys (m)": "bus_journeys_m",
    "Underground journeys (m)": "underground_journeys_m",
    "DLR Journeys (m)": "dlr_journeys_m",
    "Tram Journeys (m)": "tram_journeys_m",
    "Overground Journeys (m)": "overground_journeys_m",
    "London Cable Car Journeys (m)": "london_cable_car_journeys_m",
    "TfL Rail Journeys (m)": "tfl_rail_journeys_m",
}

TRANSPORT_COLUMNS = {
    "bus_journeys_m": "Bus",
    "underground_journeys_m": "Underground",
    "dlr_journeys_m": "DLR",
    "tram_journeys_m": "Tram",
    "overground_journeys_m": "Overground",
    "london_cable_car_journeys_m": "London Cable Car",
    "tfl_rail_journeys_m": "TfL Rail",
}

PAGE_CSS = """
<style>
    .stApp {
        background:
            radial-gradient(circle at top left, rgba(214, 233, 255, 0.9), transparent 28%),
            radial-gradient(circle at top right, rgba(255, 234, 201, 0.9), transparent 24%),
            linear-gradient(180deg, #f6f3ee 0%, #f0ece6 100%);
    }
    .hero {
        padding: 1.5rem 1.75rem;
        border-radius: 24px;
        background: linear-gradient(135deg, rgba(18, 61, 92, 0.95), rgba(28, 104, 122, 0.88));
        color: #f8fbfd;
        box-shadow: 0 18px 40px rgba(27, 46, 58, 0.18);
        margin-bottom: 1rem;
    }
    .hero h1 {
        margin: 0;
        font-size: 2.2rem;
        line-height: 1.1;
    }
    .hero p {
        margin: 0.75rem 0 0 0;
        max-width: 54rem;
        color: rgba(248, 251, 253, 0.92);
    }
    .metric-note {
        color: #4f5d6a;
        font-size: 0.95rem;
        margin-top: -0.3rem;
        margin-bottom: 0.9rem;
    }
</style>
"""


def configure_page() -> None:
    st.set_page_config(
        page_title="London Transport Analytics",
        page_icon="🚇",
        layout="wide",
    )
    st.markdown(PAGE_CSS, unsafe_allow_html=True)
    st.markdown(
        """
        <section class="hero">
            <h1>London Transport Analytics</h1>
            <p>
                A compact dashboard for monthly TfL journey trends. The app prefers the BigQuery
                mart produced by the pipeline and falls back to the public CSV transformed with the
                same business logic when cloud credentials are not configured.
            </p>
        </section>
        """,
        unsafe_allow_html=True,
    )


@st.cache_data(show_spinner=False, ttl=3600)
def fetch_public_csv() -> pd.DataFrame:
    request = urllib.request.Request(DATASET_URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=120) as response:
        content = response.read()

    return pd.read_csv(io.BytesIO(content))


def build_local_mart(source_df: pd.DataFrame) -> pd.DataFrame:
    df = source_df.rename(columns=SOURCE_COLUMNS).copy()
    df["reporting_period"] = pd.to_numeric(df["reporting_period"], errors="coerce")
    df["days_in_period"] = pd.to_numeric(df["days_in_period"], errors="coerce")
    df["period_beginning_date"] = pd.to_datetime(
        df["period_beginning"], format="%d-%b-%y", errors="coerce"
    )
    df["period_ending_date"] = pd.to_datetime(
        df["period_ending"], format="%d-%b-%y", errors="coerce"
    )

    for column in TRANSPORT_COLUMNS:
        df[column] = pd.to_numeric(df[column], errors="coerce")

    mart = df.melt(
        id_vars=[
            "period_and_financial_year",
            "reporting_period",
            "days_in_period",
            "period_beginning_date",
            "period_ending_date",
        ],
        value_vars=list(TRANSPORT_COLUMNS.keys()),
        var_name="transport_metric",
        value_name="journeys_m",
    )

    mart["transport_type"] = mart["transport_metric"].map(TRANSPORT_COLUMNS)
    mart = mart.drop(columns=["transport_metric"])
    mart = mart.dropna(subset=["period_beginning_date", "journeys_m"])
    mart["year"] = mart["period_beginning_date"].dt.year
    mart["month"] = mart["period_beginning_date"].dt.month
    mart["year_month"] = mart["period_beginning_date"].dt.strftime("%Y-%m")

    return mart.sort_values(["period_beginning_date", "transport_type"]).reset_index(drop=True)


@st.cache_data(show_spinner=False, ttl=3600)
def fetch_bigquery_mart(project_id: str, dataset_name: str, mart_table: str) -> pd.DataFrame:
    from google.cloud import bigquery

    client = bigquery.Client(project=project_id)
    query = f"""
    SELECT
        period_and_financial_year,
        reporting_period,
        days_in_period,
        period_beginning_date,
        period_ending_date,
        year,
        month,
        year_month,
        transport_type,
        journeys_m
    FROM `{project_id}.{dataset_name}.{mart_table}`
    WHERE period_beginning_date IS NOT NULL
      AND journeys_m IS NOT NULL
    ORDER BY period_beginning_date, transport_type
    """

    rows = [dict(row) for row in client.query(query).result()]
    if not rows:
        return pd.DataFrame()

    df = pd.DataFrame(rows)
    df["period_beginning_date"] = pd.to_datetime(df["period_beginning_date"], errors="coerce")
    df["period_ending_date"] = pd.to_datetime(df["period_ending_date"], errors="coerce")

    return df


def load_dataset(data_mode: str, project_id: str, dataset_name: str, mart_table: str) -> tuple[pd.DataFrame, str]:
    can_use_bigquery = bool(project_id)

    if data_mode in {"Auto", "BigQuery"} and can_use_bigquery:
        try:
            df = fetch_bigquery_mart(project_id, dataset_name, mart_table)
            if not df.empty:
                return df, "BigQuery mart"
        except Exception as exc:
            if data_mode == "BigQuery":
                st.warning(f"BigQuery connection failed, using public CSV fallback instead: {exc}")
            else:
                st.info(f"BigQuery not available, using public CSV fallback: {exc}")

    if data_mode == "BigQuery" and not can_use_bigquery:
        st.warning("Set LTA_BQ_PROJECT_ID and Google credentials to use BigQuery. Falling back to public CSV.")

    local_df = build_local_mart(fetch_public_csv())
    return local_df, "Public CSV fallback"


def render_sidebar() -> tuple[str, str, str, str]:
    st.sidebar.header("Connection")
    data_mode = st.sidebar.radio("Data source", ["Auto", "BigQuery", "Public CSV"], index=0)
    project_id = st.sidebar.text_input("GCP project ID", value=os.getenv("LTA_BQ_PROJECT_ID", ""))
    dataset_name = st.sidebar.text_input("BigQuery dataset", value=os.getenv("LTA_BQ_DATASET", "london_transport_dw"))
    mart_table = st.sidebar.text_input(
        "Mart table",
        value=os.getenv("LTA_BQ_MART_TABLE", "transport_journeys_mart"),
    )
    st.sidebar.caption(
        "If BigQuery is not configured, the dashboard uses the official TfL CSV and applies the same mart logic locally."
    )
    return data_mode, project_id, dataset_name, mart_table


def render_metrics(df: pd.DataFrame) -> None:
    latest_date = df["period_beginning_date"].max()
    latest_total = (
        df.loc[df["period_beginning_date"] == latest_date, "journeys_m"].sum()
        if pd.notna(latest_date)
        else 0.0
    )

    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Latest Period", latest_date.strftime("%Y-%m-%d") if pd.notna(latest_date) else "N/A")
    col2.metric("Latest Journeys (m)", f"{latest_total:,.1f}")
    col3.metric("Transport Modes", f"{df['transport_type'].nunique()}")
    col4.metric("Covered Periods", f"{df['period_beginning_date'].nunique()}")
    st.markdown(
        '<p class="metric-note">Values are measured in millions of journeys, following the original TfL dataset.</p>',
        unsafe_allow_html=True,
    )


def render_charts(df: pd.DataFrame) -> None:
    min_date = df["period_beginning_date"].min().date()
    max_date = df["period_beginning_date"].max().date()
    available_transports = sorted(df["transport_type"].unique())

    filter_col1, filter_col2 = st.columns([1.2, 1.8])
    with filter_col1:
        selected_range = st.date_input("Period range", value=(min_date, max_date), min_value=min_date, max_value=max_date)
    with filter_col2:
        selected_transports = st.multiselect(
            "Transport types",
            options=available_transports,
            default=available_transports,
        )

    if len(selected_range) != 2:
        st.stop()

    start_date, end_date = selected_range
    filtered = df[
        (df["period_beginning_date"].dt.date >= start_date)
        & (df["period_beginning_date"].dt.date <= end_date)
        & (df["transport_type"].isin(selected_transports))
    ]

    time_df = (
        filtered.groupby("period_beginning_date", as_index=False)["journeys_m"]
        .sum()
        .rename(columns={"journeys_m": "total_journeys_m"})
    )
    category_df = (
        filtered.groupby("transport_type", as_index=False)["journeys_m"]
        .sum()
        .rename(columns={"journeys_m": "total_journeys_m"})
        .sort_values("total_journeys_m", ascending=False)
    )

    chart_col1, chart_col2 = st.columns(2)

    with chart_col1:
        st.subheader("Total Journeys Over Time")
        time_chart = px.line(
            time_df,
            x="period_beginning_date",
            y="total_journeys_m",
            markers=True,
            color_discrete_sequence=["#0b7285"],
        )
        time_chart.update_layout(
            xaxis_title="Period beginning",
            yaxis_title="Journeys (m)",
            margin=dict(l=20, r=20, t=20, b=20),
            paper_bgcolor="rgba(0,0,0,0)",
            plot_bgcolor="rgba(255,255,255,0.75)",
        )
        st.plotly_chart(time_chart, use_container_width=True)

    with chart_col2:
        st.subheader("Journey Distribution by Transport Type")
        category_chart = px.bar(
            category_df,
            x="transport_type",
            y="total_journeys_m",
            color="transport_type",
            color_discrete_sequence=[
                "#f4a261",
                "#2a9d8f",
                "#264653",
                "#e76f51",
                "#588157",
                "#bc6c25",
                "#457b9d",
            ],
        )
        category_chart.update_layout(
            showlegend=False,
            xaxis_title="Transport type",
            yaxis_title="Journeys (m)",
            margin=dict(l=20, r=20, t=20, b=20),
            paper_bgcolor="rgba(0,0,0,0)",
            plot_bgcolor="rgba(255,255,255,0.75)",
        )
        st.plotly_chart(category_chart, use_container_width=True)

    with st.expander("Preview mart data"):
        st.dataframe(
            filtered.sort_values(["period_beginning_date", "transport_type"], ascending=[False, True]),
            use_container_width=True,
            hide_index=True,
        )


def main() -> None:
    configure_page()
    data_mode, project_id, dataset_name, mart_table = render_sidebar()
    data, source_label = load_dataset(data_mode, project_id, dataset_name, mart_table)

    if data.empty:
        st.error("No data was loaded. Check the BigQuery table or the public dataset URL.")
        st.stop()

    st.caption(f"Active data source: {source_label}")
    render_metrics(data)
    render_charts(data)


if __name__ == "__main__":
    main()
