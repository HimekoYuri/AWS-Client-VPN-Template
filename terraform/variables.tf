# AWS Region Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

# Environment Configuration
variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "dev"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "192.168.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["192.168.1.0/24", "192.168.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["192.168.10.0/24", "192.168.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

# VPN Configuration
variable "vpn_client_cidr_pc" {
  description = "Client CIDR for PC VPN"
  type        = string
  default     = "172.16.0.0/22"
}

variable "vpn_client_cidr_mobile" {
  description = "Client CIDR for Mobile VPN"
  type        = string
  default     = "172.17.0.0/22"
}

# IAM Identity Center Configuration
variable "iic_vpn_group_id" {
  description = "IAM Identity Center group ID for VPN access (deprecated - use vpn_users_group_id from iam_identity_center.tf)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vpn_user_ids" {
  description = "List of IAM Identity Center user IDs to add to VPN-Users group"
  type        = list(string)
  default     = []

}

# Certificate Configuration
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
