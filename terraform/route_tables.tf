# Route Tables Configuration
# Requirements: 4.1, 4.5 - インターネットアクセスとルーティング設定

# パブリックサブネット用ルートテーブル
# Internet Gateway経由でインターネットにアクセス
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # デフォルトルート: すべてのトラフィックをInternet Gatewayへ
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "client-vpn-public-rt"
    Type        = "Public"
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "Route table for public subnets with IGW"
  }
}

# プライベートサブネット用ルートテーブル
# NAT Gateway経由でインターネットにアクセス（静的IP使用）
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # デフォルトルート: すべてのトラフィックをNAT Gatewayへ
  # Requirements: 4.1 - VPNユーザーのトラフィックをNATゲートウェイ経由でルーティング
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "client-vpn-private-rt"
    Type        = "Private"
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "Route table for private subnets with NAT Gateway"
  }

  # NAT Gatewayが完全に作成された後にルートテーブルを作成
  depends_on = [aws_nat_gateway.main]
}

# パブリックサブネットとルートテーブルの関連付け
# 各パブリックサブネットをパブリックルートテーブルに関連付け
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# プライベートサブネットとルートテーブルの関連付け
# 各プライベートサブネットをプライベートルートテーブルに関連付け
# Client VPNエンドポイントからのトラフィックがNAT Gateway経由でインターネットにアクセス
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
