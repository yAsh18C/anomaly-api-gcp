variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west2"
}

variable "api_key" {
  description = "API key for the anomaly detection service"
  type        = string
  sensitive   = true
}

variable "image_url" {
  description = "Docker image URL in Artifact Registry"
  type        = string
}
