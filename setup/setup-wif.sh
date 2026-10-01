export GCP_PROJECT_ID="proj-sdlc"
export GITHUB_REPO="seymen/genai-go"

# 1. Enable required Google Cloud APIs
gcloud services enable \
    aiplatform.googleapis.com \
    iamcredentials.googleapis.com \
    sts.googleapis.com

# 2. Create the Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
    --location="global" \
    --display-name="GitHub Actions Pool"

# 3. Retrieve the Pool Resource Name
POOL_NAME=$(gcloud iam workload-identity-pools describe "github-pool" \
    --location="global" \
    --format="value(name)")

# 4. Create the Workload Identity Provider for GitHub Actions
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
    --workload-identity-pool="github-pool" \
    --location="global" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    --attribute-condition="assertion.repository == '${GITHUB_REPO}'"

# 5. Grant the Vertex AI role directly to the GitHub repository identity
# Note: NO service account is created or used here!
gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
    --role="roles/aiplatform.user" \
    --member="principalSet://iam.googleapis.com/${POOL_NAME}/attribute.repository/${GITHUB_REPO}"

# 6. Print the full Provider Resource path (save this for GitHub secrets)
echo "=== WIF_PROVIDER (Save to GitHub Secrets) ==="
gcloud iam workload-identity-pools providers describe "github-provider" \
    --workload-identity-pool="github-pool" \
    --location="global" \
    --format="value(name)"
