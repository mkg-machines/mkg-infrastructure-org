# -----------------------------------------------------------------------------
# Permission Set Module
# -----------------------------------------------------------------------------

variable "name" {
  description = "Permission set name"
  type        = string
}

variable "description" {
  description = "Permission set description"
  type        = string
}

variable "instance_arn" {
  description = "SSO instance ARN"
  type        = string
}

variable "session_duration" {
  description = "Session duration in ISO 8601 format"
  type        = string
  default     = "PT8H"
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs"
  type        = list(string)
  default     = []
}

variable "inline_policy" {
  description = "Inline policy JSON"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Resources
# -----------------------------------------------------------------------------

resource "aws_ssoadmin_permission_set" "this" {
  name             = var.name
  description      = var.description
  instance_arn     = var.instance_arn
  session_duration = var.session_duration
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = toset(var.managed_policy_arns)

  instance_arn       = var.instance_arn
  managed_policy_arn = each.value
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  count = var.inline_policy != null ? 1 : 0

  instance_arn       = var.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  inline_policy      = var.inline_policy
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "arn" {
  description = "Permission set ARN"
  value       = aws_ssoadmin_permission_set.this.arn
}

output "name" {
  description = "Permission set name"
  value       = aws_ssoadmin_permission_set.this.name
}
