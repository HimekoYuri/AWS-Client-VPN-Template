# ============================================================================
# Terraform & Provider Version Constraints
# ============================================================================
# Terraform 1.9+ required for:
#   - check blocks (continuous validation)
#   - import blocks
#   - moved blocks improvements
#   - terraform test framework
# AWS Provider 6.x features:
#   - Multi-region support (resource-level region attribute)
#   - Stricter boolean validation
#   - Removed deprecated resources (OpsWorks, SimpleDB, WorkLink)
#   - EIP vpc parameter removed (domain = "vpc" required)
# ============================================================================

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.39"
    }
  }
}
