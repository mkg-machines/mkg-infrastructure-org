# -----------------------------------------------------------------------------
# GitHub OIDC Provider
# -----------------------------------------------------------------------------

module "github_oidc" {
  source = "../../modules/github-oidc"

  github_org    = var.github_org
  allowed_repos = ["*"]
  role_name     = "mkg-github-actions-role"

  role_policy_arns = [
    "arn:aws:iam::aws:policy/PowerUserAccess"
  ]

  tags = local.common_tags
}
