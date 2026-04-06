# ============================================================================
# Internet Gateway and NAT Gateway Configuration
# ============================================================================
# Requirements: 4.2, 5.4, 5.5
#
# NAT Gateway modes (var.nat_gateway_mode):
#   "regional"  - 1 NAT Gateway, connectivity_type = "public" (AZ非依存)
#   "single_az" - 1 NAT Gateway in first public subnet AZ
#   "multi_az"  - 1 NAT Gateway per AZ (高可用性)
# ============================================================================

locals {
  # NAT Gatewayの数を決定
  nat_gateway_count = var.nat_gateway_mode == "multi_az" ? length(var.availability_zones) : 1
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "client-vpn-igw"
    Purpose = "Internet access for public subnets"
  }
}

# EIP: NAT Gatewayの数だけ作成
resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = {
    Name    = "client-vpn-nat-eip-${count.index + 1}"
    Purpose = "Static IP for VPN internet access"
    AZ      = var.nat_gateway_mode == "multi_az" ? var.availability_zones[count.index] : var.availability_zones[0]
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway: モードに応じて1つまたはAZごとに作成
resource "aws_nat_gateway" "main" {
  count = local.nat_gateway_count

  allocation_id     = aws_eip.nat[count.index].id
  subnet_id         = aws_subnet.public[var.nat_gateway_mode == "multi_az" ? count.index : 0].id
  connectivity_type = "public"

  tags = {
    Name    = var.nat_gateway_mode == "multi_az" ? "client-vpn-nat-gw-${var.availability_zones[count.index]}" : "client-vpn-nat-gateway"
    Purpose = "NAT for private subnet internet access"
    Mode    = var.nat_gateway_mode
  }

  depends_on = [aws_internet_gateway.main]
}
