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

output "domains_ou_id" {
  description = "Domains OU ID"
  value       = aws_organizations_organizational_unit.domains.id
}

output "domain_ou_ids" {
  description = "Domain OU IDs"
  value = {
    for domain, ou in aws_organizations_organizational_unit.domain :
    domain => ou.id
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
