output "gcs_bucket_name" {
  description = "Raw data lake bucket name"
  value       = google_storage_bucket.data_lake.name
}

output "gcs_bucket_url" {
  description = "Raw data lake bucket URL"
  value       = google_storage_bucket.data_lake.url
}

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID"
  value       = google_bigquery_dataset.warehouse.dataset_id
}

output "bigquery_dataset_location" {
  description = "BigQuery dataset location"
  value       = google_bigquery_dataset.warehouse.location
}
