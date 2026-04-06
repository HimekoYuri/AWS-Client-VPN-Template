# ============================================================================
# Terraform & Provider Version Constraints
# ============================================================================
# Terraform 1.9+ required for:
#   - check blocks (continuous validation)
#   - import blocks
#   - moved blocks improvements
#   - terraform test framework
# AWS Provider 5.80+ for latest Client VPN and IAM Identity Center features
# ============================================================================

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}
