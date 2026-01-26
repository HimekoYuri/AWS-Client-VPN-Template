# ============================================================================
# Client VPN Endpoint - スマホ用（証明書認証）
# ============================================================================
# 
# このファイルは、スマホ用のClient VPNエンドポイントを定義します。
# 認証方式: 相互TLS証明書認証（MFAなし）
#
# 要件:
# - Requirements 3.1: クライアント証明書による認証機能を提供
# - Requirements 3.2: 有効な証明書でMFA認証なしで接続を確立
# - Requirements 3.3: 無効または期限切れの証明書で接続を拒否
# - Requirements 2.5: 接続ログをCloudWatch Logsに記録
# - Requirements 5.3: プライベートサブネットに関連付け
# - Requirements 4.4: インターネットアクセス（0.0.0.0/0）を許可
# ============================================================================

# ----------------------------------------------------------------------------
# スマホ用Client VPNエンドポイント
# ----------------------------------------------------------------------------
resource "aws_ec2_client_vpn_endpoint" "mobile" {
  description            = "Client VPN Endpoint for Mobile (Certificate Auth)"
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  client_cidr_block      = var.vpn_client_cidr_mobile

  # 証明書認証設定（相互TLS）
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_client.arn
  }

  # 接続ログ設定（CloudWatch Logs）
  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn_mobile.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn_mobile.name
  }

  # ネットワーク設定
  vpc_id             = aws_vpc.main.id
  security_group_ids = [aws_security_group.vpn_endpoint.id]

  # Split Tunnel有効化（VPNトラフィックのみVPN経由）
  split_tunnel = false

  # トランスポート設定
  transport_protocol = "udp"
  vpn_port           = 443

  # セルフサービスポータル無効化（証明書認証のため不要）
  self_service_portal = "disabled"

  # DNS設定
  dns_servers = ["8.8.8.8", "8.8.4.4"]

  tags = {
    Name        = "client-vpn-mobile-endpoint"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Mobile VPN with Certificate Auth"
    AuthType    = "Certificate"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_cloudwatch_log_group.vpn_mobile,
    aws_cloudwatch_log_stream.vpn_mobile,
    aws_acm_certificate.vpn_client
  ]
}

# ----------------------------------------------------------------------------
# ネットワーク関連付け（Multi-AZ構成）
# ----------------------------------------------------------------------------
resource "aws_ec2_client_vpn_network_association" "mobile" {
  count = length(aws_subnet.private)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.mobile.id
  subnet_id              = aws_subnet.private[count.index].id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_ec2_client_vpn_endpoint.mobile
  ]
}

# ----------------------------------------------------------------------------
# 認可ルール（全認証済みユーザー許可）
# ----------------------------------------------------------------------------
resource "aws_ec2_client_vpn_authorization_rule" "mobile_internet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.mobile.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
  description            = "Allow internet access for all authenticated users"

  depends_on = [
    aws_ec2_client_vpn_network_association.mobile
  ]
}

# ----------------------------------------------------------------------------
# ルート設定（インターネットアクセス）
# ----------------------------------------------------------------------------
resource "aws_ec2_client_vpn_route" "mobile_internet" {
  count = length(aws_subnet.private)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.mobile.id
  destination_cidr_block = "0.0.0.0/0"
  target_vpc_subnet_id   = aws_ec2_client_vpn_network_association.mobile[count.index].subnet_id
  description            = "Route to internet via NAT Gateway"

  depends_on = [
    aws_ec2_client_vpn_network_association.mobile
  ]
}
