# Internet Gateway and NAT Gateway Configuration
# Requirements: 4.2, 5.4, 5.5 - インターネットアクセスと静的IP、ネットワークアーキテクチャ

# Internet Gateway
# Requirements: 5.4 - インターネットゲートウェイをVPCにアタッチする
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "client-vpn-igw"
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "Internet access for public subnets"
  }
}

# Elastic IP for NAT Gateway
# Requirements: 4.2 - Elastic IPをNATゲートウェイに割り当てる
# この静的IPがVPN経由のインターネットアクセスのソースIPとなります
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "client-vpn-nat-eip"
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "Static IP for VPN internet access"
  }

  # Internet Gatewayが作成された後にElastic IPを作成
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway
# Requirements: 5.5 - NATゲートウェイをパブリックサブネットに配置する
# Requirements: 4.2 - VPNトラフィックをNATゲートウェイ経由でルーティングする
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "client-vpn-nat-gateway"
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "NAT for private subnet internet access"
    Subnet      = aws_subnet.public[0].availability_zone
  }

  # Internet Gatewayが完全に作成された後にNAT Gatewayを作成
  # これにより、正しい順序でリソースが作成されることを保証
  depends_on = [aws_internet_gateway.main]
}
