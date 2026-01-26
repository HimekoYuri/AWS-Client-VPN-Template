# ============================================================================
# AWS Certificate Manager (ACM) - 証明書インポート
# ============================================================================
# 
# このファイルは、OpenSSL/easy-rsaで生成した自己署名証明書をACMにインポートします。
# - サーバー証明書: Client VPNエンドポイントで使用
# - クライアント証明書: スマホ用VPNの相互TLS認証で使用
#
# セキュリティ要件:
# - 証明書秘密鍵はGitにコミットしない（.gitignoreで除外）
# - lifecycle設定でcreate_before_destroyを有効化し、証明書更新時のダウンタイムを防止
# ============================================================================

# ----------------------------------------------------------------------------
# サーバー証明書のACMインポート
# ----------------------------------------------------------------------------
# Client VPNエンドポイントのサーバー証明書として使用されます。
# VPNクライアントはこの証明書を検証してサーバーの正当性を確認します。
resource "aws_acm_certificate" "vpn_server" {
  private_key       = file("${path.module}/../certs/server.vpn.example.com.key")
  certificate_body  = file("${path.module}/../certs/server.vpn.example.com.crt")
  certificate_chain = file("${path.module}/../certs/ca.crt")

  tags = {
    Name        = "client-vpn-server-cert"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Client VPN Server Certificate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------------------------------
# クライアント証明書のACMインポート（スマホ用VPN）
# ----------------------------------------------------------------------------
# スマホ用VPNエンドポイントの相互TLS認証で使用されます。
# クライアントはこの証明書を提示して認証を受けます。
resource "aws_acm_certificate" "vpn_client" {
  private_key       = file("${path.module}/../certs/client1.vpn.example.com.key")
  certificate_body  = file("${path.module}/../certs/client1.vpn.example.com.crt")
  certificate_chain = file("${path.module}/../certs/ca.crt")

  tags = {
    Name        = "client-vpn-client-cert"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Client VPN Client Certificate Mobile"
  }

  lifecycle {
    create_before_destroy = true
  }
}


