# -----------------------------------------------------------------------------
# GitHub OIDC Module
# -----------------------------------------------------------------------------

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "allowed_repos" {
  description = "List of allowed repositories or ['*'] for all"
  type        = list(string)
  default     = ["*"]
}

variable "role_name" {
  description = "IAM role name"
  type        = string
}

variable "role_policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# -----------------------------------------------------------------------------
# OIDC Provider
# -----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# IAM Role
# -----------------------------------------------------------------------------

locals {
  # Build subject conditions
  subject_conditions = var.allowed_repos[0] == "*" ? [
    "repo:${var.github_org}/*"
    ] : [
    for repo in var.allowed_repos : "repo:${var.github_org}/${repo}:*"
  ]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.subject_conditions
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  for_each = toset(var.role_policy_arns)

  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "provider_arn" {
  description = "OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "IAM role name"
  value       = aws_iam_role.github_actions.name
}
