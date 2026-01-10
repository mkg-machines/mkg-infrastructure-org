locals {
  # Load configuration files
  accounts_config = jsondecode(file("${path.module}/../../data/accounts.json"))
  users_config    = jsondecode(file("${path.module}/../../data/users.json"))

  # Extract domains from accounts
  domains = toset([for account in local.accounts_config.accounts : account.domain])

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
    PlatformDeveloper = {
      description         = "Platform domain developer access"
      managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy       = null
    }
    ProductDeveloper = {
      description         = "Product domain developer access"
      managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy       = null
    }
    ProcurementDeveloper = {
      description         = "Procurement domain developer access"
      managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy       = null
    }
    LogisticsDeveloper = {
      description         = "Logistics domain developer access"
      managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy       = null
    }
    SalesDeveloper = {
      description         = "Sales domain developer access"
      managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy       = null
    }
    MarketingDeveloper = {
      description         = "Marketing domain developer access"
      managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy       = null
    }
    ServiceDeveloper = {
      description         = "Service domain developer access"
      managed_policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy       = null
    }
    AccountingDeveloper = {
      description         = "Accounting domain developer access"
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

  # Domain to permission set mapping
  domain_permission_set_map = {
    platform    = "PlatformDeveloper"
    product     = "ProductDeveloper"
    procurement = "ProcurementDeveloper"
    logistics   = "LogisticsDeveloper"
    sales       = "SalesDeveloper"
    marketing   = "MarketingDeveloper"
    service     = "ServiceDeveloper"
    accounting  = "AccountingDeveloper"
  }

  # Common tags
  common_tags = {
    Project   = "mkg-machines"
    ManagedBy = "terraform"
  }
}
