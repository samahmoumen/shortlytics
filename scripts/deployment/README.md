# CI/CD scripts

Run from any working directory; scripts resolve the repository root themselves.

- `../ci/run-backend-tests.sh`: Maven clean verify. Requires Java 23 and PostgreSQL credentials in the environment.
- `../ci/run-frontend-checks.sh`: npm ci, ESLint, Vite build.
- `../ci/validate-terraform.sh`: format and validate all Terraform roots without configuring remote state.
- `../ci/validate-helm.sh`: package dependencies, lint, and render both environments.
- `publish-images.sh <registry> <full-git-sha>`: build, scan and push both images.
- `update-gitops-images.sh <dev|prod> <registry> <full-git-sha>`: update both component tags. Production also requires the production tenant, vault and workload identity client ID.
- `verify-rollout.sh <namespace>`: wait for application deployments.
- `smoke-test.sh <url>`: verify the frontend and backend health endpoint.
- `../rollback/rollback-gitops.sh <dev|prod> <full-git-sha>`: verify the target images exist, then set both chart tags to the known-good SHA. Review and commit the GitOps change; Argo CD performs the rollback.

Image tags are full Git commit SHAs, never `latest`. A database schema rollback is deliberately separate: Flyway migrations must be backward-compatible with the previous application version.
