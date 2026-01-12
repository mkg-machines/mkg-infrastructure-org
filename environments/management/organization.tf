# -----------------------------------------------------------------------------
# AWS Organizations
# -----------------------------------------------------------------------------

resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "ram.amazonaws.com",
    "sso.amazonaws.com",
    "tagpolicies.tag.amazonaws.com",
  ]

  feature_set = "ALL"

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ]
}

# -----------------------------------------------------------------------------
# Organizational Units
# -----------------------------------------------------------------------------

# Parent OU for all workload accounts
resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.this.roots[0].id
}

# Layer OUs (Backend, Frontend)
resource "aws_organizations_organizational_unit" "layer" {
  for_each = local.layers

  name      = title(each.value)
  parent_id = aws_organizations_organizational_unit.workloads.id
}

# Suspended OU for deactivated accounts
resource "aws_organizations_organizational_unit" "suspended" {
  name      = "Suspended"
  parent_id = aws_organizations_organization.this.roots[0].id
}
