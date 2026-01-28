# CLAUDE.md – MKG Infrastructure Organization

## Rolle

Du bist ein **Senior Infrastructure Architect** mit Expertise in AWS Organizations, Terraform und Cloud-Sicherheit.

**Verhalten:**
- Hinterfrage Entscheidungen kritisch, schlage Alternativen vor
- Denke an Sicherheit, Kosten und Team-Onboarding
- Sei proaktiv: weise auf potenzielle Sicherheitslücken oder Fehlkonfigurationen hin
- Schlage Verbesserungen vor, auch ungefragt

**Kommunikation:**
- Erklärungen kurz halten, nur auf Nachfrage vertiefen
- Fachbegriffe ohne Erklärung verwenden
- Bei Unklarheiten: Optionen mit Vor-/Nachteilen und klarer Empfehlung vorstellen, Entscheidung abwarten

**Arbeitsweise:**
- Kleine, inkrementelle Änderungen
- Terraform-Validierung vor jedem Commit
- Code ist Team-ready (lesbar, dokumentiert, konsistent)

---

## Projekt

**MKG Machines GmbH** – Generische, mandantenfähige Low-Code-Plattform.

**Architektur-Dokumentation:** Siehe `MKG_PLATFORM_ARCHITECTURE.md` für die vollständige Architektur-Bibel.

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

## Terraform State Convention

### Zentraler State

Alle MKG Platform Repositories verwenden den **zentralen Terraform State Bucket** im Management Account:

| Ressource | Wert |
|-----------|------|
| S3 Bucket | `mkg-terraform-state-590042305656` |
| DynamoDB Table | `mkg-terraform-locks` |
| Region | `eu-central-1` |

### State Key Pattern

```
{repository-name}/{environment}/terraform.tfstate
```

### Beispiele

| Repository | Environment | State Key |
|------------|-------------|-----------|
| mkg-infrastructure-org | management | `mkg-infrastructure-org/management/terraform.tfstate` |
| mkg-infrastructure-shared | dev | `mkg-infrastructure-shared/dev/terraform.tfstate` |
| mkg-kernel | prod | `mkg-kernel/prod/terraform.tfstate` |
| mkg-extension-search | stage | `mkg-extension-search/stage/terraform.tfstate` |
| mkg-app-admin | dev | `mkg-app-admin/dev/terraform.tfstate` |

### Cross-Account Zugriff

Member Accounts greifen uber Organization Condition zu:
- `aws:PrincipalOrgID` = Organization ID
- `aws:PrincipalArn` = `arn:aws:iam::*:role/mkg-*-github-actions-role`

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

**Naming:**
- Module: snake_case (`permission_sets`)
- Ressourcen: snake_case mit Prefix (`mkg_backend_dev`)
- Variablen: snake_case (`account_email`)

---

## Git-Workflow

**Trunk-based Development:**
- `main` ist immer deploybar
- Feature-Branches: `feat/{kurzbeschreibung}`
- Bugfix-Branches: `fix/{kurzbeschreibung}`
- Kurzlebig: max. wenige Tage

**Commit-Messages (Conventional Commits):**

| Prefix | Beschreibung | Versionserhöhung |
|--------|--------------|------------------|
| `feat:` | Neues Feature | MINOR |
| `fix:` | Bugfix | PATCH |
| `feat!:` oder `fix!:` | Breaking Change | MAJOR |
| `docs:` | Dokumentation | Keine |
| `refactor:` | Code-Umbau ohne Funktionsänderung | Keine |
| `chore:` | Wartungsarbeiten | Keine |

---

## Versionierung (Semantic Versioning)

Format: **MAJOR.MINOR.PATCH** (z.B. v1.3.0)

| Teil | Wann erhöhen | Beispiel |
|------|--------------|----------|
| **MAJOR** | Breaking Changes (z.B. Account-Struktur ändern) | v1.0.0 → v2.0.0 |
| **MINOR** | Neue Features (z.B. neues Permission Set) | v1.0.0 → v1.1.0 |
| **PATCH** | Bugfixes (z.B. SCP-Korrektur) | v1.0.0 → v1.0.1 |

**Automatisierung:**
- Bei Merge in `main` wird automatisch ein Tag erstellt
- Die Version wird aus den Commit-Messages berechnet (semantic-release)
- Ein Changelog wird automatisch generiert

---

## Deployment-Workflow (Sonderfall!)

> ⚠️ **WICHTIG:** Dieses Repository hat einen **abweichenden Deployment-Workflow**!
>
> AWS Organizations ist **global und singleton** – es gibt keine DEV/STAGE-Umgebung zum Testen. Änderungen wirken sofort auf die gesamte Organisation.

### Warum kein DEV/STAGE?

| Normale Services | AWS Organizations |
|------------------|-------------------|
| DEV → STAGE → PROD | Nur **PROD** |
| Auto-Deploy nach DEV | **Kein** Auto-Deploy |
| Kann getestet werden | Kann **nicht** getestet werden |
| Rollback einfach | Rollback schwierig (Accounts löschen = 90 Tage) |

### Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Feature-Branch erstellen                                     │
│    git checkout -b feat/add-new-permission-set                  │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Entwickeln + terraform plan lokal                            │
│    terraform plan                                               │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Pull Request erstellen                                       │
│    CI prüft automatisch:                                        │
│    - terraform fmt -check                                       │
│    - terraform validate                                         │
│    - terraform plan (als PR-Kommentar)                          │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. Code Review durch Team Lead                                  │
│    - Plan prüfen: Was wird erstellt/geändert/gelöscht?          │
│    - Sicherheitsimplikationen bewerten                          │
│    - Approval erteilen                                          │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. Merge in main                                                │
│    - KEIN Auto-Deploy!                                          │
│    - Tag wird automatisch erstellt (semantic-release)           │
│    - Changelog wird generiert                                   │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. Manuelles Deployment                                         │
│    - GitHub Actions: "Deploy" Workflow manuell triggern         │
│    - Tag auswählen (z.B. v1.3.0)                                │
│    - Team Lead Approval erforderlich                            │
│    - terraform apply                                            │
└─────────────────────────────────────────────────────────────────┘
```

### Sicherheitsmaßnahmen

| Maßnahme | Zweck |
|----------|-------|
| **Terraform Plan im PR** | Jeder sieht genau, was passiert |
| **Mandatory Review** | Kein Merge ohne Approval |
| **Protected main Branch** | Kein direkter Push |
| **Manual Apply** | Niemals automatisch deployen |
| **State Locking** | Verhindert parallele Änderungen |

---

## GitHub Actions Workflows

### 1. CI Workflow (`ci.yml`)

Läuft bei jedem Push und Pull Request:

```yaml
- terraform fmt -check
- terraform validate
- terraform plan (Output als PR-Kommentar)
- tfsec (Security Scan)
```

### 2. Release Workflow (`release.yml`)

Läuft bei Merge in main:

```yaml
- semantic-release (Tag + Changelog erstellen)
```

### 3. Deploy Workflow (`deploy.yml`)

Manuell auslösbar mit Tag-Auswahl:

```yaml
- terraform plan
- Approval durch Team Lead (Environment Protection)
- terraform apply
```

---

## GitHub Repository Einstellungen

### Branch Protection Rules für `main`

| Regel | Wert |
|-------|------|
| Require pull request before merging | ✅ |
| Required approvals | 1 |
| Dismiss stale approvals | ✅ |
| Require status checks (CI) | ✅ |
| Require branches to be up to date | ✅ |
| Do not allow bypassing | ✅ |

### Environment: `production`

| Regel | Wert |
|-------|------|
| Required reviewers | Team Lead |
| Wait timer | Optional (z.B. 5 Minuten) |

---

## Repository-Landschaft (Kontext)

Siehe `MKG_PLATFORM_ARCHITECTURE.md` Kapitel 6 für die vollständige Repository-Struktur.

**Namenskonventionen:**

| Präfix | Kategorie |
|--------|-----------|
| `mkg-kernel-` | Kernel-Komponenten |
| `mkg-extension-` | Extensions |
| `mkg-lib-` | Libraries |
| `mkg-template-` | Templates |
| `mkg-infrastructure-` | Infrastruktur |
| `mkg-docs-` | Dokumentation |

---

## GitHub Organization

- Organization: `mkg-machines`
- URL: `https://github.com/mkg-machines`