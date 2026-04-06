# ============================================================================
# Client VPN Endpoint - スマホ用（証明書認証）
# ============================================================================
# Requirements: 3.1, 3.2, 3.3, 2.5, 5.3, 4.4
# SAST: セッションタイムアウト設定、バナーテキスト追加
# ============================================================================

resource "aws_ec2_client_vpn_endpoint" "mobile" {
  description            = "Client VPN Endpoint for Mobile (Certificate Auth)"
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  client_cidr_block      = var.vpn_client_cidr_mobile
  session_timeout_hours  = var.vpn_session_timeout_hours

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_client.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn_mobile.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn_mobile.name
  }

  vpc_id             = aws_vpc.main.id
  security_group_ids = [aws_security_group.vpn_endpoint.id]
  split_tunnel       = false
  transport_protocol = "tcp"
  vpn_port           = 443

  self_service_portal = "disabled"

  # SAST: VPN接続時のセキュリティバナー
  client_login_banner_options {
    enabled     = true
    banner_text = "Authorized users only. All activity is monitored and logged."
  }

  dns_servers = ["8.8.8.8", "8.8.4.4"]

  tags = {
    Name     = "client-vpn-mobile-endpoint"
    Purpose  = "Mobile VPN with Certificate Auth"
    AuthType = "Certificate"
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

resource "aws_ec2_client_vpn_network_association" "mobile" {
  count = length(aws_subnet.private)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.mobile.id
  subnet_id              = aws_subnet.private[count.index].id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ec2_client_vpn_authorization_rule" "mobile_internet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.mobile.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
  description            = "Allow internet access for all authenticated users"

  depends_on = [aws_ec2_client_vpn_network_association.mobile]
}
