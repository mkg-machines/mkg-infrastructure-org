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

## Prerequisites

- Terraform >= 1.11.1
- AWS CLI configured with Management Account credentials
- AWS Organizations enabled
- AWS IAM Identity Center enabled

## Usage

### Local Development

```bash
cd environments/management
terraform init
terraform plan
terraform apply
```

### CI/CD Workflow

Changes are deployed via GitHub Actions:

1. **Push to main** → `Terraform Plan` runs automatically
2. **Review plan output** in Actions log
3. **Trigger apply** → Actions → "Terraform Apply" → Run workflow → type `apply`

## Configuration

### Accounts
Edit `data/accounts.json` to manage AWS accounts.

### Users & Groups
Edit `data/users.json` to manage SSO users and groups.

Note: Users created via Terraform need manual password reset in IAM Identity Center to receive invitation email.

## Permission Sets

| Permission Set | Description |
|----------------|-------------|
| AdminAccess | Full access to all accounts |
| BackendDeveloper | Full access to backend dev/stage, ReadOnly to prod |
| FrontendDeveloper | Full access to frontend dev/stage, ReadOnly to prod |
| ReadOnly | ReadOnly access everywhere |
| Deployer | CI/CD deployment permissions |

## SCPs

| SCP | Description |
|-----|-------------|
| RegionRestriction | Limit to eu-central-1 |
| DenyRootUser | Block root user actions |
| RequireIMDSv2 | Require EC2 IMDSv2 |
| DenyLeaveOrganization | Prevent accounts from leaving |

## State Backend

- S3 Bucket: `mkg-terraform-state-590042305656`
- DynamoDB Table: `mkg-terraform-locks`
- Region: `eu-central-1`
