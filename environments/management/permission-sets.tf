# -----------------------------------------------------------------------------
# Permission Sets
# -----------------------------------------------------------------------------

module "permission_set" {
  source   = "../../modules/permission-set"
  for_each = local.permission_sets

  name             = each.key
  description      = each.value.description
  instance_arn     = local.sso_instance_arn
  session_duration = var.sso_session_duration

  managed_policy_arns = each.value.managed_policy_arns
  inline_policy       = each.value.inline_policy
}
