provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "mkg-machines"
      ManagedBy = "terraform"
    }
  }
}
