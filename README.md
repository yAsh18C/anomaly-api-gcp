# Transaction Anomaly Detection API — GCP Cloud Run Deployment

Production FastAPI service for real-time financial transaction anomaly detection, deployed to Google Cloud Platform using Terraform Infrastructure as Code.

**Live (Render):** transaction-anomaly-api.onrender.com  
**Live (GCP Cloud Run):** https://anomaly-api-qmzjirl6jq-nw.a.run.app  
**API Docs:** https://anomaly-api-qmzjirl6jq-nw.a.run.app/docs  
**Source API repo:** github.com/yAsh18C/transaction-anomaly-api

---

## Architecture

```
GitHub Actions CI/CD
        |
        v
Artifact Registry  ──>  Cloud Run (europe-west2)
        ^                      |
        |                      | reads secret
  Docker build            Secret Manager
                               |
                         API Key (anomaly-api-key)
                               |
                     IAM Service Account
                     (least-privilege access)
```

**Request flow:**
1. Client sends POST /predict with transaction features and API key header
2. Cloud Run authenticates request via API key pulled from Secret Manager
3. Isolation Forest model scores transaction (ROC-AUC 0.971)
4. SHAP TreeExplainer returns per-feature attributions
5. Response includes anomaly score, confidence, and top contributing features

---

## Infrastructure (Terraform)

All GCP resources are provisioned declaratively via Terraform. No manual console clicks required.

| Resource | Purpose |
|---|---|
| `google_cloud_run_v2_service` | Serverless container hosting the FastAPI app |
| `google_artifact_registry_repository` | Private Docker image registry |
| `google_secret_manager_secret` | Secure API key storage |
| `google_service_account` | Dedicated identity for Cloud Run with least-privilege IAM |
| `google_secret_manager_secret_iam_member` | Grants Cloud Run SA read access to the secret |
| `google_cloud_run_v2_service_iam_member` | Allows public unauthenticated invocation |

### Infrastructure decisions

**Cloud Run over Compute Engine:** Cloud Run scales to zero when idle (no cost), scales up automatically under load, and requires no VM management. Ideal for an API with variable traffic.

**Secret Manager over environment variables:** API keys in environment variables are visible in Cloud Run console logs and deployment configs. Secret Manager encrypts at rest, version-controls secrets, and enforces IAM access control.

**Isolation Forest over One-Class SVM:** 4x faster inference (0.007 ms vs 0.031 ms per transaction), native SHAP TreeExplainer support for compliance-grade explainability, negligible ROC-AUC difference (0.971 vs 0.973).

**europe-west2 (London) region:** Lowest latency for UK financial services use cases; aligns with data residency requirements common in regulated industries.

---

## Model Performance

Trained on 284,807 Kaggle credit card transactions (492 fraud cases, 0.17% contamination).

| Metric | Isolation Forest | One-Class SVM | LOF |
|---|---|---|---|
| ROC-AUC | 0.971 | 0.973 | failed |
| F1 | 0.560 | 0.448 | 0.000 |
| Latency | 0.007 ms | 0.031 ms | N/A |

---

## Deploy from Scratch

### Prerequisites

- GCP account with billing enabled
- `gcloud` CLI authenticated (`gcloud auth application-default login`)
- Terraform >= 1.5
- Docker

### Steps

```bash
# 1. Enable required GCP APIs
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable artifactregistry.googleapis.com

# 2. Create Artifact Registry repository
gcloud artifacts repositories create anomaly-api-repo \
  --repository-format=docker \
  --location=europe-west2

# 3. Build and push Docker image
docker build -t europe-west2-docker.pkg.dev/<PROJECT_ID>/anomaly-api-repo/anomaly-api:latest .
gcloud auth configure-docker europe-west2-docker.pkg.dev
docker push europe-west2-docker.pkg.dev/<PROJECT_ID>/anomaly-api-repo/anomaly-api:latest

# 4. Deploy with Terraform
terraform init
terraform plan
terraform apply
```

### terraform.tfvars

```hcl
project_id = "your-gcp-project-id"
region     = "europe-west2"
api_key    = "your-api-key"
image_url  = "europe-west2-docker.pkg.dev/your-project/anomaly-api-repo/anomaly-api:latest"
```

---

## API Usage

### Health check

```bash
curl https://anomaly-api-qmzjirl6jq-nw.a.run.app/health
```

### Predict

```bash
curl -X POST https://anomaly-api-qmzjirl6jq-nw.a.run.app/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{"v1": -1.36, "v2": -0.07, ..., "amount": 149.62}'
```

### Example response

```json
{
  "transaction_id": 1,
  "anomaly_score": -0.406,
  "is_anomaly": false,
  "confidence": "high",
  "top_features": [
    {"feature": "v17", "shap_value": 0.348, "direction": "toward_normal"},
    {"feature": "v11", "shap_value": 0.286, "direction": "toward_normal"},
    {"feature": "amount", "shap_value": -0.281, "direction": "toward_anomaly"}
  ],
  "timestamp": "2026-10-14T14:58:59.856551"
}
```

---

## Tear Down

```bash
terraform destroy
```

Removes all GCP resources. No lingering costs.

---

## Tech Stack

Python, FastAPI, Scikit-learn, SHAP, Docker, Terraform, GCP Cloud Run, GCP Artifact Registry, GCP Secret Manager, GCP IAM
