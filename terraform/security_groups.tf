# ============================================================================
# Security Groups Configuration
# ============================================================================
# Requirements: 5.6, 7.3 - 最小権限のセキュリティグループ
# SAST: インラインルールではなく個別ルールリソースを使用
# ============================================================================

resource "aws_security_group" "vpn_endpoint" {
  name        = "client-vpn-endpoint-sg"
  description = "Security group for Client VPN endpoints"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "client-vpn-endpoint-sg"
    Purpose = "Client VPN Endpoint Security"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# SAST: 個別ルールリソースで管理（インラインルールは非推奨）
resource "aws_vpc_security_group_ingress_rule" "vpn_tcp" {
  security_group_id = aws_security_group.vpn_endpoint.id
  description       = "VPN client traffic - TCP 443"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "vpn-tcp-443-ingress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpn_udp" {
  security_group_id = aws_security_group.vpn_endpoint.id
  description       = "VPN client traffic - UDP 443"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "udp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "vpn-udp-443-ingress"
  }
}

resource "aws_vpc_security_group_egress_rule" "vpn_all_outbound" {
  security_group_id = aws_security_group.vpn_endpoint.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "vpn-all-egress"
  }
}
