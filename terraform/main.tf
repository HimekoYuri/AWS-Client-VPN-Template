# AWS Provider Configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "AWS Client VPN"
      ManagedBy   = "Terraform"
      Environment = "Production"
    }
  }
}
