# Shortlytics 🔗📊

URL shortener with click analytics, deployed on Azure Kubernetes Service with Terraform, Argo CD and Azure Key Vault.

![Java](https://img.shields.io/badge/Java-23-orange?logo=openjdk)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.4-6DB33F?logo=springboot&logoColor=white)
![React](https://img.shields.io/badge/React-Vite-61DAFB?logo=react&logoColor=black)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/AKS-326CE5?logo=kubernetes&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo%20CD-EF7B4D?logo=argo&logoColor=white)

## Overview

Authenticated users can create short URLs, manage their links, and view click activity over time. The app is a React frontend and a Spring Boot REST API backed by PostgreSQL, running on AKS. Terraform provisions the Azure infrastructure, Argo CD deploys from Git, and secrets are delivered from Key Vault through Workload Identity, so no cloud credentials are stored in images or in the repo.

## Architecture

![Architecture](images/image.png)

- **Terraform** provisions Azure resources and identities.
- **Argo CD** reconciles Kubernetes application state from Git.
- **Kubernetes (AKS)** runs the frontend and backend workloads.
- **PostgreSQL** stores users, short URLs and click events.

## Features

- JWT authentication with Spring Security and BCrypt-hashed passwords
- Short URL creation, link management, and per-URL and total click analytics
- Public `302` redirect that records each click
- Flyway-versioned schema migrations
- Multi-stage Docker builds for frontend and backend
- Health, liveness and readiness probes, Prometheus metrics, graceful shutdown
- Secrets from Azure Key Vault via External Secrets Operator and Workload Identity

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | React, Vite, Nginx |
| Backend | Java 23, Spring Boot 3.4, Spring Security, Spring Data JPA, JJWT |
| Database | PostgreSQL, Flyway |
| Infrastructure | Azure (AKS, ACR, Key Vault, VNet), Terraform |
| Delivery | Docker, Helm, Argo CD |
| Observability | Spring Boot Actuator, Micrometer, Prometheus |

## How to run

### Locally

**Prerequisites:** Java 23, Node.js 20+, PostgreSQL

1. Create a PostgreSQL database named `url_shortener_db`.
2. Set the backend environment variables:

   ```bash
   export DB_URL="jdbc:postgresql://localhost:5432/url_shortener_db"
   export DB_USERNAME="postgres"
   export DB_PASSWORD="<password>"
   export JWT_SECRET="<strong-secret>"
   export JWT_EXPIRATION="86400000"
   ```

3. Start the backend (Flyway applies migrations on startup):

   ```bash
   cd backend
   ./mvnw spring-boot:run
   ```

4. Start the frontend in a second terminal:

   ```bash
   cd frontend
   npm install
   npm run dev
   ```

### On Azure

**Prerequisites:** Azure CLI, Terraform, `kubectl`, Helm

```bash
# 1. Bootstrap Terraform prerequisites (remote state)
cd terraform/bootstrap
terraform init
terraform apply

# 2. Provision the dev environment
cd ../environments/dev
terraform init
terraform plan -out=dev.tfplan
terraform apply dev.tfplan

# 3. Deploy the application through Argo CD
cd ../../..
./scripts/deploy-dev.sh
```

Use `terraform/environments/prod` for production. Other helpers: `scripts/sync-infra.sh`, `scripts/setup-argocd-secrets.sh`.

## API

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| `POST` | `/api/auth/public/register` | Public | Create an account |
| `POST` | `/api/auth/public/login` | Public | Log in and receive a JWT |
| `POST` | `/api/urls/shorten` | User | Create a short URL |
| `GET` | `/api/urls/myurls` | User | List your URLs |
| `GET` | `/api/urls/analytics/{shortUrl}` | User | Click analytics for one URL |
| `GET` | `/api/urls/totalClicks` | User | Total clicks by date |
| `GET` | `/{shortUrl}` | Public | Redirect to the original URL |

Protected endpoints expect `Authorization: Bearer <JWT>`.

## Database schema

The domain has three entities, mapped with Spring Data JPA in `backend/src/main/java/com/url/shortener/models/`. The schema is created and versioned by Flyway migrations, and Hibernate only validates it (`ddl-auto=validate`).

```mermaid
erDiagram
    USER ||--o{ URL_MAPPING : owns
    URL_MAPPING ||--o{ CLICK_EVENT : records

    USER {
        bigint id PK
        string username
        string email
        string password
        string role
    }

    URL_MAPPING {
        bigint id PK
        string original_url
        string short_url
        bigint click_count
        datetime created_date
        bigint user_id FK
    }

    CLICK_EVENT {
        bigint id PK
        datetime click_date
        bigint url_mapping_id FK
    }
```

- A **user** owns many **URL mappings**, and a mapping has many **click events**.
- Passwords are stored as BCrypt hashes, and new users get `ROLE_USER`.
- `click_count` is a quick aggregate for display, and `click_event` keeps one row per click for time-based analytics.

Simplified entity mapping:

```java
@Entity
public class UrlMapping {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String originalUrl;
    private String shortUrl;          // 8-character alphanumeric code
    private int clickCount;
    private LocalDateTime createdDate;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;                // owner

    @OneToMany(mappedBy = "urlMapping")
    private List<ClickEvent> clickEvents;
}

@Entity
public class ClickEvent {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private LocalDateTime clickDate;

    @ManyToOne
    @JoinColumn(name = "url_mapping_id")
    private UrlMapping urlMapping;
}
```

## Key decisions

- **Workload Identity over client secrets:** no Azure credentials in pods, images or Git.
- **GitOps with Argo CD:** deployments are reviewable commits, and cluster drift is corrected automatically.
- **Flyway with `ddl-auto=validate`:** schema changes are versioned instead of mutated by Hibernate.
- **Both `click_count` and `ClickEvent`:** the counter gives fast display, the events give time-based analytics.

## Known limitations and next steps

- Short-code generation has no collision retry; add a `UNIQUE(short_url)` constraint with retry.
- Click recording is synchronous on the redirect path; move it to async ingestion.
- Analytics are grouped in Java; use database-side aggregation and indexes.
- The JWT is kept in browser storage; consider an `HttpOnly` cookie.
- Analytics date ranges are hard-coded in the frontend.

## Repository structure

```text
shortlytics/
├── backend/            # Spring Boot API
├── frontend/           # React + Vite app
├── gitops-manifests/   # Kubernetes / Helm / Argo CD config
├── scripts/            # Deployment helpers
├── terraform/          # bootstrap, environments (dev, prod), modules
├── images/             # README images
└── README.md
```