variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "mkg-machines"
}

variable "sso_session_duration" {
  description = "SSO session duration in ISO 8601 format"
  type        = string
  default     = "PT8H"
}
