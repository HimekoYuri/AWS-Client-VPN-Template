# ============================================================================
# AWS Certificate Manager (ACM) - 証明書インポート
# ============================================================================
# サーバー証明書: Client VPNエンドポイントで使用
# クライアント証明書: スマホ用VPNの相互TLS認証で使用
# SAST: 証明書秘密鍵はGitにコミットしない（.gitignoreで除外）
# ============================================================================

resource "aws_acm_certificate" "vpn_server" {
  private_key       = file("${path.module}/../certs/server.vpn.example.com.key")
  certificate_body  = file("${path.module}/../certs/server.vpn.example.com.crt")
  certificate_chain = file("${path.module}/../certs/ca.crt")

  tags = {
    Name    = "client-vpn-server-cert"
    Purpose = "Client VPN Server Certificate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "vpn_client" {
  private_key       = file("${path.module}/../certs/client1.vpn.example.com.key")
  certificate_body  = file("${path.module}/../certs/client1.vpn.example.com.crt")
  certificate_chain = file("${path.module}/../certs/ca.crt")

  tags = {
    Name    = "client-vpn-client-cert"
    Purpose = "Client VPN Client Certificate Mobile"
  }

  lifecycle {
    create_before_destroy = true
  }
}
