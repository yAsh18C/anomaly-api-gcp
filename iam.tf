resource "google_service_account" "cloud_run_sa" {
  account_id   = "anomaly-api-sa"
  display_name = "Anomaly API Service Account"
}

resource "google_secret_manager_secret_iam_member" "cloud_run_secret_access" {
  secret_id = google_secret_manager_secret.api_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.anomaly_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
