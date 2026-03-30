variable "project" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default GCP region for provider operations"
  type        = string
  default     = "europe-west2"
}

variable "location" {
  description = "Location for GCS bucket and BigQuery dataset"
  type        = string
  default     = "europe-west2"
}

variable "gcs_bucket_name" {
  description = "Globally unique GCS bucket name for the raw data lake"
  type        = string
}

variable "bq_dataset_name" {
  description = "BigQuery dataset name for downstream warehouse tables"
  type        = string
  default     = "london_transport_dw"
}
