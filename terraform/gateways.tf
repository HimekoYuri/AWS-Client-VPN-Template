# ============================================================================
# Internet Gateway and NAT Gateway Configuration
# ============================================================================
# Requirements: 4.2, 5.4, 5.5
# ============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "client-vpn-igw"
    Purpose = "Internet access for public subnets"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name    = "client-vpn-nat-eip"
    Purpose = "Static IP for VPN internet access"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name    = "client-vpn-nat-gateway"
    Purpose = "NAT for private subnet internet access"
  }

  depends_on = [aws_internet_gateway.main]
}
