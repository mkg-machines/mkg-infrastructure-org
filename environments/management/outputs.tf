# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "organization_id" {
  description = "AWS Organizations ID"
  value       = aws_organizations_organization.this.id
}

output "organization_root_id" {
  description = "AWS Organizations root ID"
  value       = aws_organizations_organization.this.roots[0].id
}

output "workloads_ou_id" {
  description = "Workloads OU ID"
  value       = aws_organizations_organizational_unit.workloads.id
}

output "layer_ou_ids" {
  description = "Layer OU IDs (Backend, Frontend)"
  value = {
    for layer, ou in aws_organizations_organizational_unit.layer :
    layer => ou.id
  }
}

output "suspended_ou_id" {
  description = "Suspended OU ID"
  value       = aws_organizations_organizational_unit.suspended.id
}

output "account_ids" {
  description = "Map of account names to account IDs"
  value = {
    for name, account in aws_organizations_account.member :
    name => account.id
  }
}

output "sso_instance_arn" {
  description = "SSO instance ARN"
  value       = local.sso_instance_arn
}

output "sso_identity_store_id" {
  description = "SSO identity store ID"
  value       = local.sso_identity_store_id
}

output "permission_set_arns" {
  description = "Map of permission set names to ARNs"
  value = {
    for name, ps in module.permission_set :
    name => ps.arn
  }
}

output "group_ids" {
  description = "Map of group names to group IDs"
  value = {
    for name, group in aws_identitystore_group.this :
    name => group.group_id
  }
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = module.github_oidc.provider_arn
}

output "github_oidc_role_arn" {
  description = "GitHub OIDC role ARN"
  value       = module.github_oidc.role_arn
}

# -----------------------------------------------------------------------------
# Terraform State Outputs (for all repositories)
# -----------------------------------------------------------------------------

output "terraform_state_bucket_name" {
  description = "Name of the central Terraform state bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_bucket_arn" {
  description = "ARN of the central Terraform state bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "terraform_locks_table_name" {
  description = "Name of the Terraform state lock table"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "terraform_locks_table_arn" {
  description = "ARN of the Terraform state lock table"
  value       = aws_dynamodb_table.terraform_locks.arn
}
