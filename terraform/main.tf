# ============================================================================
# AWS Provider Configuration
# ============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "AWS Client VPN"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# ============================================================================
# Data Sources - 共通
# ============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
