locals {
  # Load configuration files
  accounts_config = jsondecode(file("${path.module}/../../data/accounts.json"))
  users_config    = jsondecode(file("${path.module}/../../data/users.json"))

  # Extract layers from accounts
  layers = toset([for account in local.accounts_config.accounts : account.layer])

  # Environments
  environments = toset(["dev", "stage", "prod"])

  # Accounts map for for_each
  accounts_map = {
    for account in local.accounts_config.accounts :
    account.name => account
  }

  # Groups map for for_each
  groups_map = {
    for group in local.users_config.groups :
    group.name => group
  }

  # Users map for for_each (exclude _schema)
  users_map = {
    for user in local.users_config.users :
    user.user_name => user
  }

  # Permission Sets configuration
  permission_sets = {
    AdminAccess = {
      description         = "Full administrator access"
      managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      inline_policy       = null
    }
    BackendDeveloper = {
      description         = "Backend developer access"
      managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy       = null
    }
    FrontendDeveloper = {
      description         = "Frontend developer access"
      managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy       = null
    }
    ReadOnly = {
      description         = "Read-only access"
      managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      inline_policy       = null
    }
    Deployer = {
      description         = "CI/CD deployment access"
      managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy       = null
    }
  }

  # Layer to permission set mapping
  layer_permission_set_map = {
    backend  = "BackendDeveloper"
    frontend = "FrontendDeveloper"
  }

  # Common tags
  common_tags = {
    Project   = "mkg-machines"
    ManagedBy = "terraform"
  }
}
