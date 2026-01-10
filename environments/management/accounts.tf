# -----------------------------------------------------------------------------
# AWS Accounts
# -----------------------------------------------------------------------------

resource "aws_organizations_account" "member" {
  for_each = local.accounts_map

  name      = each.value.name
  email     = each.value.email
  parent_id = aws_organizations_organizational_unit.domain[each.value.domain].id

  # Prevent accidental deletion
  close_on_deletion = false

  # IAM user access to billing
  iam_user_access_to_billing = "ALLOW"

  tags = merge(local.common_tags, {
    Domain      = each.value.domain
    Environment = each.value.environment
  })

  lifecycle {
    ignore_changes = [
      # Email cannot be changed after creation
      email,
    ]
  }
}
