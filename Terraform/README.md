# Terraform Infrastructure

This module provisions the base GCP resources required by London Transport Analytics.

## Provisioned Resources

- Google Cloud Storage bucket for the raw data lake
- BigQuery dataset for raw, mart, and dashboard objects

## Files

- `main.tf`: provider and resource definitions
- `variables.tf`: input variables
- `outputs.tf`: provisioned resource outputs
- `terraform.tfvars.example`: example runtime configuration
- `setup.ps1`: credentials helper
- `deploy.ps1`: `terraform init`, `plan`, and `apply` helper

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- Google Cloud SDK (`gcloud`)
- a GCP service account with permissions for bucket and dataset creation

From the repository root on Windows:

```powershell
.\scripts\bootstrap_windows.ps1
.\scripts\check_prereqs.ps1
```

## Authentication

Set `GOOGLE_APPLICATION_CREDENTIALS` to your service account JSON path:

```powershell
.\setup.ps1 -CredentialsPath "C:\path\to\service-account.json"
```

## Configuration

Create a working variable file:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Update:

- `project`
- `region`
- `location`
- `gcs_bucket_name`
- `bq_dataset_name`

## Deploy

```powershell
.\deploy.ps1
```

Manual alternative:

```powershell
terraform init
terraform plan
terraform apply
```

## Cleanup

```powershell
terraform destroy
```

## Notes

- The bucket name must be globally unique.
- Align the Terraform bucket, dataset, project, and location values with the KV values used in Kestra.
- `terraform init -backend=false` and `terraform validate` were run locally on March 29, 2026.
