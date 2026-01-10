# -----------------------------------------------------------------------------
# AWS IAM Identity Center (SSO)
# -----------------------------------------------------------------------------

# Get existing SSO instance
data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  sso_identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

# -----------------------------------------------------------------------------
# Groups
# -----------------------------------------------------------------------------

resource "aws_identitystore_group" "this" {
  for_each = local.groups_map

  identity_store_id = local.sso_identity_store_id
  display_name      = each.value.name
  description       = each.value.description
}

# -----------------------------------------------------------------------------
# Users
# -----------------------------------------------------------------------------

resource "aws_identitystore_user" "this" {
  for_each = local.users_map

  identity_store_id = local.sso_identity_store_id

  user_name    = each.value.user_name
  display_name = each.value.display_name

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value   = each.value.email
    primary = true
  }

  locale   = lookup(each.value, "locale", "de-DE")
  timezone = lookup(each.value, "timezone", "Europe/Berlin")
}

# -----------------------------------------------------------------------------
# Group Memberships
# -----------------------------------------------------------------------------

locals {
  # Flatten user-group relationships for group membership
  user_group_memberships = flatten([
    for user_name, user in local.users_map : [
      for group_name in user.groups : {
        user_name  = user_name
        group_name = group_name
        key        = "${user_name}-${group_name}"
      }
    ]
  ])

  user_group_membership_map = {
    for membership in local.user_group_memberships :
    membership.key => membership
  }
}

resource "aws_identitystore_group_membership" "this" {
  for_each = local.user_group_membership_map

  identity_store_id = local.sso_identity_store_id
  group_id          = aws_identitystore_group.this[each.value.group_name].group_id
  member_id         = aws_identitystore_user.this[each.value.user_name].user_id
}
