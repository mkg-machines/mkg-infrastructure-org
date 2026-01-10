# MKG Infrastructure Org

Terraform configuration for AWS Organizations, SSO, and GitHub OIDC.

## Overview

This repository manages:
- AWS Organizations with 25 accounts (1 Management + 24 Member)
- AWS IAM Identity Center (SSO)
- Permission Sets for domain-based access control
- GitHub OIDC for CI/CD pipelines
- Service Control Policies (SCPs)

## Account Structure

```
Root
├── Management Account (mkg-management)
├── Domains OU
│   ├── Platform OU (mkg-platform-dev/stage/prod)
│   ├── Product OU (mkg-product-dev/stage/prod)
│   ├── Procurement OU (mkg-procurement-dev/stage/prod)
│   ├── Logistics OU (mkg-logistics-dev/stage/prod)
│   ├── Sales OU (mkg-sales-dev/stage/prod)
│   ├── Marketing OU (mkg-marketing-dev/stage/prod)
│   ├── Service OU (mkg-service-dev/stage/prod)
│   └── Accounting OU (mkg-accounting-dev/stage/prod)
└── Suspended OU
```

## Prerequisites

- Terraform >= 1.6.0
- AWS CLI configured with Management Account credentials
- AWS Organizations enabled
- AWS IAM Identity Center enabled

## Usage

```bash
cd environments/management
terraform init
terraform plan
terraform apply
```

## Configuration

### Accounts
Edit `data/accounts.json` to manage AWS accounts.

### Users & Groups
Edit `data/users.json` to manage SSO users and groups.

## Permission Sets

| Permission Set | Description |
|----------------|-------------|
| AdminAccess | Full access to all accounts |
| {Domain}Developer | Full access to dev/stage, ReadOnly to prod |
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
