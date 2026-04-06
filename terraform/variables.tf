# ============================================================================
# Variables
# ============================================================================

# ----------------------------------------------------------------------------
# AWS Configuration
# ----------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier (e.g. ap-northeast-1)."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}

# ----------------------------------------------------------------------------
# VPC Configuration
# ----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "192.168.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["192.168.1.0/24", "192.168.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required for Multi-AZ."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["192.168.10.0/24", "192.168.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnets are required for Multi-AZ."
  }
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for Multi-AZ."
  }
}

# ----------------------------------------------------------------------------
# VPN Configuration
# ----------------------------------------------------------------------------
variable "vpn_client_cidr_pc" {
  description = "Client CIDR for PC VPN"
  type        = string
  default     = "172.16.0.0/22"

  validation {
    condition     = can(cidrhost(var.vpn_client_cidr_pc, 0))
    error_message = "vpn_client_cidr_pc must be a valid CIDR block."
  }
}

variable "vpn_client_cidr_mobile" {
  description = "Client CIDR for Mobile VPN"
  type        = string
  default     = "172.17.0.0/22"

  validation {
    condition     = can(cidrhost(var.vpn_client_cidr_mobile, 0))
    error_message = "vpn_client_cidr_mobile must be a valid CIDR block."
  }
}

variable "vpn_session_timeout_hours" {
  description = "VPN session timeout in hours"
  type        = number
  default     = 8

  validation {
    condition     = contains([8, 10, 12, 24], var.vpn_session_timeout_hours)
    error_message = "vpn_session_timeout_hours must be one of: 8, 10, 12, 24."
  }
}

# ----------------------------------------------------------------------------
# IAM Identity Center Configuration
# ----------------------------------------------------------------------------
variable "vpn_user_ids" {
  description = "List of IAM Identity Center user IDs to add to VPN-Users group"
  type        = list(string)
  default     = []
}

# ----------------------------------------------------------------------------
# Certificate Configuration
# ----------------------------------------------------------------------------
variable "organization_name" {
  description = "Organization name for certificates"
  type        = string
  default     = "YourOrganization"
}

variable "vpn_domain" {
  description = "Domain name for VPN server certificate"
  type        = string
  default     = "vpn.example.com"
}

# ----------------------------------------------------------------------------
# Logging Configuration
# ----------------------------------------------------------------------------
variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch Logs retention value."
  }
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}
