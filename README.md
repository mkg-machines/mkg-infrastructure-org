# MKG Infrastructure Org

Terraform configuration for AWS Organizations, SSO, and GitHub OIDC.

## Overview

This repository manages:
- AWS Organizations with 7 accounts (1 Management + 6 Member)
- AWS IAM Identity Center (SSO)
- Permission Sets for layer-based access control
- GitHub OIDC for CI/CD pipelines
- Service Control Policies (SCPs)

## Account Structure

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

## Quick Links

- **AWS Access Portal:** https://d-996743e9a4.awsapps.com/start
- **Management Account ID:** 590042305656

## Prerequisites

- Terraform >= 1.11.1
- AWS CLI configured with Management Account credentials
- AWS Organizations enabled
- AWS IAM Identity Center enabled

## CI/CD Workflow

> **Wichtig:** AWS Organizations ist global und singleton – es gibt keine DEV/STAGE-Umgebung. Änderungen wirken sofort auf die gesamte Organisation.

### Workflow-Übersicht

```
Feature Branch → PR → CI (Plan) → Review → Merge → Release (Tag) → Deploy (Manual)
```

### 1. CI Workflow (`ci.yml`)

Läuft automatisch bei Push und Pull Request:
- `terraform fmt -check`
- `terraform validate`
- `terraform plan` (Output als PR-Kommentar)
- `tfsec` (Security Scan)

### 2. Release Workflow (`release.yml`)

Läuft automatisch bei Merge in `main`:
- Erstellt automatisch einen Git Tag (semantic-release)
- Erstellt GitHub Release mit Changelog

### 3. Deploy Workflow (`deploy.yml`)

Manuell auslösbar:
1. GitHub → Actions → "Deploy"
2. Tag auswählen (z.B. `v1.0.4`)
3. Bestätigung: `deploy` eingeben
4. Approval durch Team Lead (Environment Protection)
5. `terraform apply` wird ausgeführt

## Local Development

```bash
# Login via SSO
aws sso login --profile mkg-management

# Terraform ausführen
cd environments/management
AWS_PROFILE=mkg-management terraform init
AWS_PROFILE=mkg-management terraform plan
AWS_PROFILE=mkg-management terraform apply
```

## User Management

### Neuen User anlegen

1. **User in `data/users.json` hinzufügen:**

```json
{
  "user_name": "max-mustermann",
  "display_name": "Max Mustermann",
  "email": "max.mustermann@example.com",
  "given_name": "Max",
  "family_name": "Mustermann",
  "department": "Development",
  "title": "Software Developer",
  "manager": "admin@example.com",
  "phone": null,
  "locale": "de-DE",
  "timezone": "Europe/Berlin",
  "groups": ["BackendDevelopers"],
  "tags": {
    "Project": "mkg-machines",
    "Role": "Developer",
    "CostCenter": "IT-520100"
  }
}
```

2. **Verfügbare Gruppen:**

| Gruppe | Permission Set | Zugriff |
|--------|----------------|---------|
| `Admins` | AdminAccess | Full Access auf alle Accounts |
| `BackendDevelopers` | BackendDeveloper | Full auf dev/stage, ReadOnly auf prod |
| `FrontendDevelopers` | FrontendDeveloper | Full auf dev/stage, ReadOnly auf prod |
| `ReadOnlyUsers` | ReadOnly | ReadOnly auf alle Accounts |
| `Deployers` | Deployer | CI/CD Deployment-Rechte |

3. **Commit, Push, PR erstellen:**

```bash
git checkout -b feat/add-user-max-mustermann
git add data/users.json
git commit -m "feat: add user Max Mustermann"
git push -u origin feat/add-user-max-mustermann
gh pr create --title "feat: add user Max Mustermann" --body "Add new backend developer"
```

4. **Nach Merge: Deploy-Workflow triggern** (siehe oben)

5. **Passwort-Reset durchführen:**
   - AWS Console → IAM Identity Center → Users
   - User auswählen → "Reset password"
   - User erhält Einladungs-E-Mail

### Bestehenden User importieren

Falls ein User bereits in AWS Identity Center existiert (z.B. manuell angelegt):

1. **User-ID ermitteln:**
```bash
aws identitystore list-users \
  --identity-store-id d-996743e9a4 \
  --filters AttributePath=UserName,AttributeValue=<USERNAME> \
  --query 'Users[0].UserId' \
  --output text \
  --region eu-central-1 \
  --profile mkg-management
```

2. **In Terraform State importieren:**
```bash
cd environments/management
AWS_PROFILE=mkg-management terraform import \
  'aws_identitystore_user.this["<USERNAME>"]' \
  d-996743e9a4/<USER_ID>
```

3. **User in `data/users.json` hinzufügen** (mit exakt gleichem `user_name`)

4. **Apply ausführen:**
```bash
AWS_PROFILE=mkg-management terraform apply
```

### User löschen

1. User aus `data/users.json` entfernen
2. PR erstellen und mergen
3. Deploy-Workflow triggern

> **Hinweis:** Der User wird aus AWS Identity Center entfernt und verliert sofort alle Zugänge.

## Permission Sets

| Permission Set | Zielgruppe | Dev | Stage | Prod |
|----------------|------------|-----|-------|------|
| `AdminAccess` | Plattform-Admins | Full | Full | Full |
| `BackendDeveloper` | Backend-Entwickler | Full | Full | ReadOnly |
| `FrontendDeveloper` | Frontend-Entwickler | Full | Full | ReadOnly |
| `ReadOnly` | Stakeholder, Support | ReadOnly | ReadOnly | ReadOnly |
| `Deployer` | CI/CD Pipelines | Deploy | Deploy | Deploy |

## Service Control Policies (SCPs)

| SCP | Zweck |
|-----|-------|
| `RegionRestriction` | Beschränkt auf eu-central-1 |
| `DenyRootUser` | Verhindert Root-User-Nutzung in Member-Accounts |
| `RequireIMDSv2` | Erzwingt IMDSv2 für EC2 |
| `DenyLeaveOrganization` | Verhindert, dass Accounts die Organization verlassen |

## Project Structure

```
mkg-infrastructure-org/
├── .github/
│   └── workflows/
│       ├── ci.yml          # CI: fmt, validate, plan, tfsec
│       ├── release.yml     # Automatic versioning
│       └── deploy.yml      # Manual deployment
├── data/
│   ├── accounts.json       # AWS Account definitions
│   └── users.json          # SSO Users and Groups
├── environments/
│   └── management/         # Terraform configuration
├── modules/                 # Reusable modules
├── .releaserc.json         # semantic-release config
├── CLAUDE.md               # AI assistant context
└── README.md
```

## State Backend

| Resource | Value |
|----------|-------|
| S3 Bucket | `mkg-terraform-state-590042305656` |
| DynamoDB Table | `mkg-terraform-locks` |
| Region | `eu-central-1` |

## Commit Convention

Dieses Repository verwendet [Conventional Commits](https://www.conventionalcommits.org/) für automatische Versionierung:

| Prefix | Beschreibung | Version |
|--------|--------------|---------|
| `feat:` | Neues Feature | MINOR |
| `fix:` | Bugfix | PATCH |
| `feat!:` / `fix!:` | Breaking Change | MAJOR |
| `docs:` | Dokumentation | - |
| `chore:` | Wartung | - |
