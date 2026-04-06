# ============================================================================
# Route Tables Configuration
# ============================================================================
# Requirements: 4.1, 4.5
#
# multi_az: AZごとにルートテーブルを作成し、対応するNAT Gatewayへルーティング
# single_az / regional: 共通のルートテーブル1つで全プライベートサブネットをルーティング
# ============================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "client-vpn-public-rt"
    Type = "Public"
  }
}

# multi_az: AZごとのプライベートルートテーブル
resource "aws_route_table" "private_per_az" {
  count  = var.nat_gateway_mode == "multi_az" ? length(var.availability_zones) : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "client-vpn-private-rt-${var.availability_zones[count.index]}"
    Type = "Private"
    AZ   = var.availability_zones[count.index]
  }

  depends_on = [aws_nat_gateway.main]
}

# single_az / regional: 共通プライベートルートテーブル
resource "aws_route_table" "private_shared" {
  count  = var.nat_gateway_mode != "multi_az" ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "client-vpn-private-rt"
    Type = "Private"
  }

  depends_on = [aws_nat_gateway.main]
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id = aws_subnet.private[count.index].id
  route_table_id = (
    var.nat_gateway_mode == "multi_az"
    ? aws_route_table.private_per_az[count.index].id
    : aws_route_table.private_shared[0].id
  )
}
