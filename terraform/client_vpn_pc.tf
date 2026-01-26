# ============================================================================
# Client VPN Endpoint - PC用（SAML + MFA認証）
# ============================================================================
# 
# このファイルは、PC用のClient VPNエンドポイントを定義します。
# 認証方式: IAM Identity Center（SAML 2.0）+ MFA
#
# 要件:
# - Requirements 2.1: IAM Identity Centerと連携した認証機能を提供
# - Requirements 2.2: MFA認証を要求
# - Requirements 2.5: 接続ログをCloudWatch Logsに記録
# - Requirements 5.3: プライベートサブネットに関連付け
# - Requirements 4.4: インターネットアクセス（0.0.0.0/0）を許可
# ============================================================================

# ----------------------------------------------------------------------------
# PC用Client VPNエンドポイント
# ----------------------------------------------------------------------------
resource "aws_ec2_client_vpn_endpoint" "pc" {
  description            = "Client VPN Endpoint for PC (SAML + MFA)"
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  client_cidr_block      = var.vpn_client_cidr_pc

  # SAML認証設定（IAM Identity Center連携）
  authentication_options {
    type                           = "federated-authentication"
    saml_provider_arn              = aws_iam_saml_provider.vpn_client.arn
    self_service_saml_provider_arn = aws_iam_saml_provider.vpn_self_service.arn
  }

  # 接続ログ設定（CloudWatch Logs）
  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn_pc.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn_pc.name
  }

  # ネットワーク設定
  vpc_id             = aws_vpc.main.id
  security_group_ids = [aws_security_group.vpn_endpoint.id]

  # Split Tunnel有効化（VPNトラフィックのみVPN経由）
  split_tunnel = true

  # トランスポート設定
  transport_protocol = "udp"
  vpn_port           = 443

  # セルフサービスポータル有効化
  self_service_portal = "enabled"

  # DNS設定
  dns_servers = ["8.8.8.8", "8.8.4.4"]

  tags = {
    Name        = "client-vpn-pc-endpoint"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "PC VPN with SAML + MFA"
    AuthType    = "SAML"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_cloudwatch_log_group.vpn_pc,
    aws_cloudwatch_log_stream.vpn_pc,
    aws_iam_saml_provider.vpn_client,
    aws_iam_saml_provider.vpn_self_service
  ]
}

# ----------------------------------------------------------------------------
# ネットワーク関連付け（Multi-AZ構成）
# ----------------------------------------------------------------------------
resource "aws_ec2_client_vpn_network_association" "pc" {
  count = length(aws_subnet.private)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.pc.id
  subnet_id              = aws_subnet.private[count.index].id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_ec2_client_vpn_endpoint.pc
  ]
}

# ----------------------------------------------------------------------------
# 認可ルール（グループベース）
# ----------------------------------------------------------------------------
# Terraformで作成したVPN-UsersグループIDを使用
# または、既存のグループIDを使用（var.iic_vpn_group_idが設定されている場合）
# ----------------------------------------------------------------------------
resource "aws_ec2_client_vpn_authorization_rule" "pc_internet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.pc.id
  target_network_cidr    = "0.0.0.0/0"
  access_group_id        = var.iic_vpn_group_id != "" ? var.iic_vpn_group_id : aws_identitystore_group.vpn_users.group_id
  description            = "Allow internet access for VPN group members"

  depends_on = [
    aws_ec2_client_vpn_network_association.pc
  ]
}

# ----------------------------------------------------------------------------
# ルート設定（インターネットアクセス）
# ----------------------------------------------------------------------------
resource "aws_ec2_client_vpn_route" "pc_internet" {
  count = length(aws_subnet.private)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.pc.id
  destination_cidr_block = "0.0.0.0/0"
  target_vpc_subnet_id   = aws_ec2_client_vpn_network_association.pc[count.index].subnet_id
  description            = "Route to internet via NAT Gateway"

  depends_on = [
    aws_ec2_client_vpn_network_association.pc
  ]
}
