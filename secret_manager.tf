resource "google_secret_manager_secret" "api_key" {
  secret_id = "anomaly-api-key"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "api_key_version" {
  secret      = google_secret_manager_secret.api_key.id
  secret_data = var.api_key
}
