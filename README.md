# 🚀 Shortlytics

Shortlytics is an enterprise-grade URL shortener and analytics platform built on a modern microservices architecture. The project implements advanced DevOps practices, GitOps automation, and secure infrastructure provisioning on Kubernetes.

---

## 🏗️ Architecture & Tech Stack

* **Backend:** Java, Spring Boot, Spring Data JPA, Flyway (Database Migrations).
* **Frontend:** React, Vite.
* **Cloud & Infrastructure:** Microsoft Azure (AKS), Proxmox VE.
* **IaC & GitOps:** Terraform / OpenTofu, Crossplane, Helm, ArgoCD.
* **Security & DevSecOps:** Kong API Gateway, External Secrets Operator, Azure Key Vault, Checkov, Trivy, SonarQube.
* **Observability:** Prometheus, Grafana, Loki, OpenTelemetry, Spring Boot Actuator.

---

## 📂 Project Structure

```text
.
├── backend/               # Spring Boot backend application (REST API)
├── frontend/              # React frontend application
├── gitops-manifests/      # Kubernetes manifests and ArgoCD configurations
├── scripts/               # Automation and deployment scripts (Bash)
│   ├── deploy-dev.sh      # Deploys the development environment
│   ├── sync-infra.sh      # Synchronizes Terraform state and applies changes
│   └── setup-argocd-secrets.sh # Configures secrets for ArgoCD synchronization
└── terraform/             # Infrastructure as Code (IaC) modules
    ├── bootstrap/         # Initial cloud setup (state storage, backend init)
    ├── environments/      # Environment-specific configurations
    │   ├── dev/           # Development environment setup & tfvars
    │   └── prod/          # Production environment setup & tfvars
    └── modules/           # Reusable Terraform modules
        ├── compute/       # Virtual machines and container compute resources
        ├── network/       # VPC, subnets, and routing configurations
        └── security/      # Key vaults, firewalls, and security policies

```

---

## ⚙️ Prerequisites

Make sure you have the following tools installed on your local machine:

* **Java SDK** (v17 or higher)
* **Node.js** (v18+) & **npm**
* **Docker** & **Kubernetes CLI (`kubectl`)**
* **Terraform** (v1.5+) or **OpenTofu**
* **Helm** (v3+)
* **Azure CLI** (if provisioning resources on Azure)

---

## 🚀 Local Development Setup

### 1. Run the Backend

Navigate to the backend directory, configure your local environment variables (such as database URL and JWT secret), and run the application:

```bash
cd backend
export JWT_SECRET="your_secure_jwt_secret_here"
export DB_URL="jdbc:postgresql://localhost:5432/url_shortener_db"
mvn spring-boot:run

```

### 2. Run the Frontend

In a separate terminal, start the React application:

```bash
cd frontend
npm install
npm run dev

```

---

## 🌍 How to Run Terraform

The infrastructure is provisioned using modular Terraform configurations divided into **bootstrap** and specific **environments** (`dev` / `prod`), leveraging custom modules (`compute`, `network`, `security`).

### Step 1: Bootstrap (Initial Setup)

If setting up the backend state storage and initial prerequisites for the first time:

```bash
cd terraform/bootstrap
terraform init
terraform plan
terraform apply

```

### Step 2: Deploying an Environment (e.g., Development)

To provision or update the development infrastructure:

1. Navigate to the dev environment folder:
```bash
cd terraform/environments/dev

```


2. Initialize Terraform (downloads required providers like `azurerm` locked via `.terraform.lock.hcl`):
```bash
terraform init

```


3. Preview the infrastructure changes:
```bash
terraform plan -out=dev.tfplan

```


4. Apply the configuration:
```bash
terraform apply dev.tfplan

```



*(Note: For production, navigate to `terraform/environments/prod/` and repeat the same steps).*

---

## 🛠️ Automation Scripts

The `scripts/` directory provides helper utilities to streamline workflows:

* **Deploy to Dev:** Run the deployment automation script:
```bash
./scripts/deploy-dev.sh

```


* **Sync Infrastructure:** Automate state validation and updates:
```bash
./scripts/sync-infra.sh

```


* **Setup ArgoCD Secrets:** Inject required GitOps secrets:
```bash
./scripts/setup-argocd-secrets.sh

```



---

## 🔒 Security & Best Practices

* **No Plaintext Secrets:** Sensitive values (like `jwt.secret` or DB credentials) are managed via environment variables and injected securely using **External Secrets Operator** integrated with **Azure Key Vault**.
* **State Management:** Terraform state files (`*.tfstate`) and execution plans (`*.tfplan`) are strictly ignored via `.gitignore` to prevent leaking secrets.



```
