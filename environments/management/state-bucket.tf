# -----------------------------------------------------------------------------
# Terraform State Infrastructure
# -----------------------------------------------------------------------------
# NOTE: The S3 bucket and DynamoDB table were created externally.
# Import them with:
#   terraform import aws_s3_bucket.terraform_state mkg-terraform-state-590042305656
#   terraform import aws_dynamodb_table.terraform_locks mkg-terraform-locks
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# S3 Bucket for Terraform State
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  bucket = "mkg-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.common_tags, {
    Name    = "mkg-terraform-state-${data.aws_caller_identity.current.account_id}"
    Purpose = "Terraform State Storage"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# S3 Bucket Policy - Cross-Account Access
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Management Account - Terraform State Operations (local operations)
      {
        Sid    = "ManagementAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      },
      # Member Accounts - Terraform State Operations
      {
        Sid       = "MemberAccountStateAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          # Only accounts within the AWS Organization
          StringEquals = {
            "aws:PrincipalOrgID" = aws_organizations_organization.this.id
          }
          # Only GitHub Actions roles with MKG naming convention
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/mkg-*-github-actions-role"
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# DynamoDB Table for Terraform Locks
# -----------------------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "mkg-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name    = "mkg-terraform-locks"
    Purpose = "Terraform State Locking"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# DynamoDB Resource Policy - Cross-Account Access
# -----------------------------------------------------------------------------

resource "aws_dynamodb_resource_policy" "terraform_locks" {
  resource_arn = aws_dynamodb_table.terraform_locks.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "MemberAccountLockAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = aws_dynamodb_table.terraform_locks.arn
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = aws_organizations_organization.this.id
          }
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/mkg-*-github-actions-role"
          }
        }
      }
    ]
  })
}
