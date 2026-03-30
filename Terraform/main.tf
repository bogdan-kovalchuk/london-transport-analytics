terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_storage_bucket" "data_lake" {
  name                        = var.gcs_bucket_name
  location                    = var.location
  storage_class               = "STANDARD"
  force_destroy               = true
  uniform_bucket_level_access = true

  labels = {
    project = "london-transport-analytics"
    layer   = "raw"
  }

  lifecycle_rule {
    condition {
      age = 1
    }

    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

resource "google_bigquery_dataset" "warehouse" {
  dataset_id                 = var.bq_dataset_name
  project                    = var.project
  location                   = var.location
  delete_contents_on_destroy = true

  labels = {
    project = "london-transport-analytics"
    layer   = "warehouse"
  }
}
