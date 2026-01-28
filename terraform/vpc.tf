# VPC Configuration
# Requirements: 5.1 - VPCを作成し、適切なCIDRブロックを割り当てる

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "client-vpn-vpc"
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "AWS Client VPN Infrastructure"
  }
}
