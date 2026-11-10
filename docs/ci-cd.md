# Shortlytics CI/CD

## Delivery model

- Pull requests to `develop` and `main`: backend tests, frontend lint/build, Dockerfile checks, Terraform validation, Helm lint/render, secret scanning, CodeQL, and dependency vulnerability scanning.
- A successful push to `develop`: GitHub Actions builds and scans the backend/frontend images, pushes them to the development ACR using the full source commit SHA, and commits the same SHA into `values-dev.yaml`. Argo CD reconciles the development Application.
- Production: manually dispatch **Promote to production** from `main`, enter the full 40-character SHA that was deployed to development, and pass the protected GitHub Environment approval. The workflow copies the exact images from development ACR to production ACR and opens a GitOps pull request against `main`. Production is deployed only after that PR is reviewed and merged.

The GitOps repository remains the deployment source of truth. CI never runs `kubectl apply` for application releases. Image tags are immutable commit SHAs; no `latest` tag is used by the pipeline.

## GitHub repository configuration

Create GitHub Environments named exactly:

- `development`
- `production` (configure required reviewers here)

Add these repository/environment variables:

| Variable | Environment | Value |
|---|---|---|
| `AZURE_CLIENT_ID_DEV` | development | Entra application/service-principal client ID for the dev workflow |
| `AZURE_CLIENT_ID_PROD` | production | Entra application/service-principal client ID for production promotion |
| `AZURE_TENANT_ID` | both | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | both | Azure subscription ID |

Do not add Azure client secrets. Configure federated credentials in Microsoft Entra ID for the GitHub Actions identities. For the environment-scoped credentials, use these subjects:

- `repo:samahmoumen/shortlytics:environment:development`
- `repo:samahmoumen/shortlytics:environment:production`

Issuer: `https://token.actions.githubusercontent.com`; audience: `api://AzureADTokenExchange`.

Assign least-privilege Azure roles to the two workflow identities:

- Development identity: `Reader` on `shortlytics-dev-rg`, and `AcrPush` on the development ACR.
- Production identity: `Reader` on both environment resource groups, `AcrPull` on development ACR, and `AcrPush` on production ACR.

The workflow uses the resource-group names `shortlytics-dev-rg` and `shortlytics-prod-rg`. The Terraform production root must be provisioned before production promotion. The production identity must be able to read ACR and managed-identity metadata in both resource groups.

For GitHub Actions, allow the repository token to write contents and create pull requests. The workflow declares the minimum per-workflow permissions. If branch protection blocks the development GitOps commit, replace that direct push with an automated PR and merge policy for the `develop` GitOps-only change.

## Terraform bootstrap and prerequisites

The Azure remote-state backend already points to the storage account `tfstateshortlytics`, container `tfstate`, with separate state keys for dev and prod. Provision the bootstrap root once before running environment roots. The CI Terraform job intentionally uses `init -backend=false`: it validates configuration without credentials or changing remote state.

Terraform currently creates a Key Vault database username/password and the JWT signing secret expected by the ExternalSecret. The JWT value is generated as 32 random bytes and stored Base64-encoded because the backend decodes `jwt.secret` as Base64.

The Kubernetes federated identity subject must match the Helm-generated service account name. Dev uses `system:serviceaccount:shortlytics-dev:shortlytics-dev-backend-backend-sa`; prod uses `system:serviceaccount:shortlytics-prod:shortlytics-prod-backend-backend-sa`.

## Argo CD

The dev Application tracks `develop`; the prod Application tracks `main`. Both use the same umbrella Helm chart with environment-specific values. The old Argo CD Image Updater annotations were removed from the dev Application: they conflict with CI's explicit SHA-based GitOps write-back and could overwrite the intended image version.

The repository is public, so Argo CD can read it without a GitHub PAT. If you later make it private, configure a read-only repository credential in Argo CD; do not put a PAT in Git or a workflow file.

## Operational notes

- The current PostgreSQL StatefulSet is a single in-cluster instance with a PVC. It is suitable for a small environment, not production-grade HA or disaster recovery. Before real production traffic, use a managed PostgreSQL service with backups, PITR, and a tested restore process.
- Keep Flyway migrations backward-compatible with the currently running application version. Application rollback does not automatically reverse a database migration.
- The production promotion workflow opens a PR; Argo CD will deploy only after it is merged. Configure required status checks and CODEOWNERS/review rules for the GitOps paths.
- The pipeline validates Terraform but does not run `terraform apply`. Infrastructure changes should use a separately approved plan/apply workflow with remote-state locking and environment approvals.
- `scripts/deployment/smoke-test.sh <namespace> <frontend-url>` checks the frontend and reaches the backend actuator health endpoint through a temporary `kubectl port-forward`. Run it from a machine that has cluster access and can reach the frontend URL.
- `scripts/rollback/rollback-gitops.sh <dev|prod> <full-sha>` verifies both images exist and updates the environment's image tags. Review and commit that GitOps change; Argo CD reconciles it. Database rollback remains a separate operation.
