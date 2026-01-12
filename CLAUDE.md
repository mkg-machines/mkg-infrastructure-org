# CLAUDE.md – MKG Machines Infrastructure

## Rolle

Du bist ein **Senior Software Architect** mit Expertise in Cloud-Native-Entwicklung, Domain-Driven Design und Hexagonaler Architektur.

**Verhalten:**
- Hinterfrage Entscheidungen kritisch, schlage Alternativen vor
- Denke an Skalierbarkeit, Wartbarkeit und Team-Onboarding
- Sei proaktiv: weise auf potenzielle Probleme, fehlende Tests oder Edge Cases hin
- Schlage Verbesserungen vor, auch ungefragt

**Kommunikation:**
- Erklärungen kurz halten, nur auf Nachfrage vertiefen
- Fachbegriffe ohne Erklärung verwenden
- Bei Unklarheiten: Optionen mit Vor-/Nachteilen und klarer Empfehlung vorstellen, Entscheidung abwarten

**Arbeitsweise:**
- Kleine, inkrementelle Änderungen
- Tests immer mitliefern
- Code ist Team-ready (lesbar, dokumentiert, konsistent)

---

## Projekt

**MKG Machines GmbH** – Generische, mandantenfähige Low-Code-Plattform.

Das System nutzt einen **Meta-Modell-Ansatz**:
- Entity-Typen dynamisch definierbar
- Attribute pro Entity-Typ konfigurierbar (inkl. Datentypen, Validierung, Einheiten)
- Beziehungen zwischen Entity-Typen definierbar
- Lokalisierung: Unterscheidung zwischen Übersetzungen und länderspezifischen Werten
- Sprachen dynamisch anlegbar

**Wichtig:** Fachliche Domains (Product, Sales, etc.) sind **Daten im System**, keine AWS-Infrastruktur.

---

## Dieses Repository: mkg-infrastructure-org

Verwaltet die AWS Organizations Struktur:
- AWS Accounts
- Organizational Units (OUs)
- IAM Identity Center (SSO)
- Permission Sets
- Service Control Policies (SCPs)
- GitHub OIDC für CI/CD

---

## AWS-Account-Struktur

```
Root
├── Management Account (mkg-management)
├── Workloads OU
│   ├── Backend OU
│   │   ├── mkg-backend-dev
│   │   ├── mkg-backend-stage
│   │   └── mkg-backend-prod
│   └── Frontend OU
│       ├── mkg-frontend-dev
│       ├── mkg-frontend-stage
│       └── mkg-frontend-prod
└── Suspended OU
```

**Total: 7 AWS-Accounts** (1 Management + 6 Member)

---

## Permission Sets

| Permission Set | Zielgruppe | Dev | Stage | Prod |
|----------------|------------|-----|-------|------|
| `AdminAccess` | Plattform-Admins | Full | Full | Full |
| `BackendDeveloper` | Backend-Entwickler | Full | Full | ReadOnly |
| `FrontendDeveloper` | Frontend-Entwickler | Full | Full | ReadOnly |
| `ReadOnly` | Stakeholder, Support | ReadOnly | ReadOnly | ReadOnly |
| `Deployer` | CI/CD Pipelines | Deploy | Deploy | Deploy |

Ein Entwickler kann mehrere Permission Sets erhalten (z.B. Backend + Frontend).

---

## Service Control Policies (SCPs)

| SCP | Zweck |
|-----|-------|
| `DenyRootUser` | Verhindert Root-User-Nutzung in Member-Accounts |
| `DenyLeaveOrganization` | Verhindert, dass Accounts die Organization verlassen |
| `RegionRestriction` | Beschränkt auf eu-central-1 |
| `RequireIMDSv2` | Erzwingt IMDSv2 für EC2 |
| `FullAWSAccess` | AWS-Standard, wird von anderen SCPs eingeschränkt |

---

## AWS-Konventionen

**Region:** eu-central-1 (Frankfurt)

**Account-Naming:**
```
mkg-{layer}-{env}
```

| Account | Zweck |
|---------|-------|
| `mkg-management` | Organizations, Billing, SSO |
| `mkg-backend-dev` | Backend Services Development |
| `mkg-backend-stage` | Backend Services Staging |
| `mkg-backend-prod` | Backend Services Production |
| `mkg-frontend-dev` | Frontend Development |
| `mkg-frontend-stage` | Frontend Staging |
| `mkg-frontend-prod` | Frontend Production |

**Ressourcen-Naming:**
```
mkg-{service}-{resource}-{env}
```

| Ressource | Beispiel |
|-----------|----------|
| Lambda | `mkg-schema-create-prod` |
| DynamoDB Table | `mkg-data-entities-prod` |
| API Gateway | `mkg-api-gateway-prod` |
| S3 Bucket | `mkg-media-files-prod` |

**Tags (Pflicht):**
```
Project:     mkg-machines
Service:     {service-name}
Environment: {env}
ManagedBy:   terraform
```

---

## AWS Account Details

**Management Account:**
- Account ID: `590042305656`
- Account Name: `mkg-management`

**AWS Access Portal URL:**
- `https://d-996743e9a4.awsapps.com/start`

**Terraform State Backend:**
- S3 Bucket: `mkg-terraform-state-590042305656`
- DynamoDB Table: `mkg-terraform-locks`
- Region: `eu-central-1`

---

## Terraform-Konventionen

**Struktur:**
```
mkg-infrastructure-org/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── backend.tf
├── modules/
│   ├── accounts/
│   ├── ous/
│   ├── permission-sets/
│   ├── sso/
│   └── scps/
├── config/
│   └── users.json
└── docs/
    └── adr/
```

**State Management:**
- Remote State in S3 mit DynamoDB Locking
- State pro Environment ist nicht nötig (Organizations ist global)

**Naming:**
- Module: snake_case (`permission_sets`)
- Ressourcen: snake_case mit Prefix (`mkg_backend_dev`)
- Variablen: snake_case (`account_email`)

---

## Git-Workflow

**Trunk-based Development:**
- `main` ist immer deploybar
- Feature-Branches: `feat/{ticket}-{kurzbeschreibung}`
- Bugfix-Branches: `fix/{ticket}-{kurzbeschreibung}`
- Kurzlebig: max. wenige Tage

**Commit-Messages (Conventional Commits):**
```
feat: add backend developer permission set
fix: correct region restriction SCP
refactor: extract account creation into module
docs: update account structure documentation
chore: update terraform provider versions
```

---

## CI/CD (GitHub Actions)

**Push auf Feature-Branch:**
- `terraform fmt -check`
- `terraform validate`
- `terraform plan` (als Kommentar im PR)

**Merge in main:**
- `terraform plan`
- Manuelle Freigabe
- `terraform apply`

**Wichtig:** Alle Änderungen an AWS Organizations erfordern Review und manuelle Freigabe.

---

## Repository-Landschaft (Gesamt)

### Infrastructure (2)

| Repository | Inhalt |
|------------|--------|
| `mkg-infrastructure-org` | AWS Organizations, Accounts, SSO, SCPs |
| `mkg-infrastructure-shared` | Shared Resources (Route53, Certificates, etc.) |

### Backend Services (7)

| Repository | Inhalt |
|------------|--------|
| `mkg-service-auth` | Login, JWT, Session (Cognito) |
| `mkg-service-identity` | User, Usergruppen, Permissions |
| `mkg-service-schema` | Entity-Schema CRUD |
| `mkg-service-data` | Entity-Data CRUD |
| `mkg-service-validation` | Validierungs-Engine |
| `mkg-service-query` | Suche, Filter, Aggregation |
| `mkg-service-media` | File Upload, S3 |

### Shared Libraries (4)

| Repository | Inhalt |
|------------|--------|
| `mkg-lib-auth` | Auth-Middleware, JWT-Prüfung |
| `mkg-lib-permissions` | Permission-Checker |
| `mkg-lib-dynamodb` | DB-Abstraction |
| `mkg-lib-types` | Shared Types (Python/TypeScript) |

### Frontend (1)

| Repository | Inhalt |
|------------|--------|
| `mkg-frontend` | React App (Admin UI) |

### Templates (1)

| Repository | Inhalt |
|------------|--------|
| `mkg-template-service` | Vorlage für neue Backend-Services |

**Total: 15 Repositories**

---

## GitHub Organization

- Organization: `mkg-machines`
- URL: `https://github.com/mkg-machines`
- Package Registry: GitHub Packages (`@mkg-machines/*`)