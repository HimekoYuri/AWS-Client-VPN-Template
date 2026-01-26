# Subnet Configuration
# Requirements: 5.2 - パブリックサブネットとプライベートサブネットを作成する

# パブリックサブネット（NAT Gateway配置用）
# Multi-AZ構成: ap-northeast-1a, ap-northeast-1c
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "client-vpn-public-subnet-${count.index + 1}"
    Type        = "Public"
    Environment = "production"
    ManagedBy   = "terraform"
    AZ          = var.availability_zones[count.index]
  }
}

# プライベートサブネット（Client VPNエンドポイント関連付け用）
# Multi-AZ構成: ap-northeast-1a, ap-northeast-1c
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "client-vpn-private-subnet-${count.index + 1}"
    Type        = "Private"
    Environment = "production"
    ManagedBy   = "terraform"
    AZ          = var.availability_zones[count.index]
  }
}
