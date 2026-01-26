# Security Groups Configuration
# Requirements: 5.6 - セキュリティグループでClient VPNエンドポイントへの適切なトラフィックのみを許可
# Requirements: 7.3 - 必要最小限のポート・プロトコルのみを許可

resource "aws_security_group" "vpn_endpoint" {
  name        = "client-vpn-endpoint-sg"
  description = "Security group for Client VPN endpoints - allows UDP 443 for VPN connections"
  vpc_id      = aws_vpc.main.id

  # VPNクライアントからのインバウンドトラフィック（UDP 443）
  ingress {
    description = "VPN client traffic - UDP 443"
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # インターネットへの全アウトバウンドトラフィックを許可
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "client-vpn-endpoint-sg"
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "Client VPN Endpoint Security"
  }

  lifecycle {
    create_before_destroy = true
  }
}
