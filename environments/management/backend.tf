terraform {
  backend "s3" {
    bucket       = "mkg-terraform-state-590042305656"
    key          = "mkg-infrastructure-org/management/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}
