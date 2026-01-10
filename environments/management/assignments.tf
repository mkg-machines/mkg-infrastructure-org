# -----------------------------------------------------------------------------
# Permission Set Assignments
# -----------------------------------------------------------------------------

locals {
  # Build assignment map for domain developers
  # Full access to dev/stage, ReadOnly to prod
  domain_developer_assignments = flatten([
    for domain in local.domains : [
      for env in local.environments : {
        key            = "${domain}-${env}-developer"
        group_name     = "${title(domain)}Developers"
        account_name   = "mkg-${domain}-${env}"
        permission_set = env == "prod" ? "ReadOnly" : local.domain_permission_set_map[domain]
      }
    ]
  ])

  domain_developer_assignment_map = {
    for assignment in local.domain_developer_assignments :
    assignment.key => assignment
  }

  # Admin assignments - full access to all accounts
  admin_assignments = {
    for name, account in local.accounts_map :
    "admin-${name}" => {
      group_name     = "Admins"
      account_name   = name
      permission_set = "AdminAccess"
    }
  }

  # ReadOnly assignments - read access to all accounts
  readonly_assignments = {
    for name, account in local.accounts_map :
    "readonly-${name}" => {
      group_name     = "ReadOnlyUsers"
      account_name   = name
      permission_set = "ReadOnly"
    }
  }

  # Deployer assignments - deploy access to all accounts
  deployer_assignments = {
    for name, account in local.accounts_map :
    "deployer-${name}" => {
      group_name     = "Deployers"
      account_name   = name
      permission_set = "Deployer"
    }
  }

  # Combine all assignments
  all_assignments = merge(
    local.domain_developer_assignment_map,
    local.admin_assignments,
    local.readonly_assignments,
    local.deployer_assignments
  )
}

# -----------------------------------------------------------------------------
# Account Assignments
# -----------------------------------------------------------------------------

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.all_assignments

  instance_arn       = local.sso_instance_arn
  permission_set_arn = module.permission_set[each.value.permission_set].arn

  principal_id   = aws_identitystore_group.this[each.value.group_name].group_id
  principal_type = "GROUP"

  target_id   = aws_organizations_account.member[each.value.account_name].id
  target_type = "AWS_ACCOUNT"
}
