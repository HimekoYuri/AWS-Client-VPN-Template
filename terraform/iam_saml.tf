# ============================================================================
# IAM SAML Identity Provider Configuration
# ============================================================================
# このファイルは、AWS Client VPN用のIAM SAML Identity Providerを定義します。
# IAM Identity Center（旧AWS SSO）と連携し、SAML 2.0認証を実現します。
#
# Requirements: 1.4, 2.1
# ============================================================================

# ----------------------------------------------------------------------------
# VPN Client用 SAML Identity Provider
# ----------------------------------------------------------------------------
# PC用VPNエンドポイントで使用するSAMLプロバイダー
# IAM Identity CenterのSAML Applicationから取得したメタデータを使用
#
# SAML Application設定:
#   - Display Name: "VPN Client"
#   - Application ACS URL: http://127.0.0.1:35001
#   - Application SAML Audience: urn:amazon:webservices:clientvpn
#
# Attribute Mappings:
#   - Subject: ${user:email} (emailAddress format)
#   - Name: ${user:email} (unspecified format)
#   - FirstName: ${user:givenName} (unspecified format)
#   - LastName: ${user:familyName} (unspecified format)
#   - memberOf: ${user:groups} (unspecified format)
# ----------------------------------------------------------------------------

resource "aws_iam_saml_provider" "vpn_client" {
  name = "aws-client-vpn"

  # SAMLメタデータファイルの読み込み
  # ファイルパス: metadata/vpn-client-metadata.xml
  # 
  # 【重要】このファイルは手動で配置する必要があります：
  # 1. IAM Identity Centerコンソールにアクセス
  # 2. Applications > "VPN Client" を選択
  # 3. "IAM Identity Center metadata" セクションから "Download metadata file" をクリック
  # 4. ダウンロードしたファイルを metadata/vpn-client-metadata.xml として保存
  #
  # セキュリティ上の注意:
  # - SAMLメタデータには機密情報が含まれるため、.gitignoreで除外されています
  # - メタデータファイルは暗号化されたストレージに保管してください
  #
  # 注意: 実際のデプロイ前に、必ず実際のSAMLメタデータファイルを配置してください
  saml_metadata_document = file("${path.module}/../metadata/vpn-client-saml-metadata.xml")

  tags = {
    Name        = "aws-client-vpn-saml-provider"
    Purpose     = "Client VPN SAML Authentication"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ----------------------------------------------------------------------------
# VPN Self-Service Portal用 SAML Identity Provider
# ----------------------------------------------------------------------------
# VPN Self-Service Portalで使用するSAMLプロバイダー
# ユーザーが自分でVPN設定ファイルをダウンロードできるポータル用
#
# SAML Application設定:
#   - Display Name: "VPN Client Self Service"
#   - Application Start URL: https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml
#
# Attribute Mappings:
#   - Subject: ${user:email} (emailAddress format)
#   - Name: ${user:email} (unspecified format)
# ----------------------------------------------------------------------------

resource "aws_iam_saml_provider" "vpn_self_service" {
  name = "aws-client-vpn-self-service"

  # SAMLメタデータファイルの読み込み
  # ファイルパス: metadata/vpn-self-service-metadata.xml
  # 
  # 【重要】このファイルは手動で配置する必要があります：
  # 1. IAM Identity Centerコンソールにアクセス
  # 2. Applications > "VPN Client Self Service" を選択
  # 3. "IAM Identity Center metadata" セクションから "Download metadata file" をクリック
  # 4. ダウンロードしたファイルを metadata/vpn-self-service-metadata.xml として保存
  #
  # セキュリティ上の注意:
  # - SAMLメタデータには機密情報が含まれるため、.gitignoreで除外されています
  # - メタデータファイルは暗号化されたストレージに保管してください
  #
  # 注意: 実際のデプロイ前に、必ず実際のSAMLメタデータファイルを配置してください
  saml_metadata_document = file("${path.module}/../metadata/vpn-client-saml-metadata.xml")

  tags = {
    Name        = "aws-client-vpn-self-service-saml-provider"
    Purpose     = "Client VPN Self-Service Portal SAML Authentication"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ----------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------

output "vpn_client_saml_provider_arn" {
  description = "VPN Client用SAML Identity ProviderのARN"
  value       = aws_iam_saml_provider.vpn_client.arn
}

output "vpn_self_service_saml_provider_arn" {
  description = "VPN Self-Service Portal用SAML Identity ProviderのARN"
  value       = aws_iam_saml_provider.vpn_self_service.arn
}

output "vpn_client_saml_provider_name" {
  description = "VPN Client用SAML Identity Providerの名前"
  value       = aws_iam_saml_provider.vpn_client.name
}

output "vpn_self_service_saml_provider_name" {
  description = "VPN Self-Service Portal用SAML Identity Providerの名前"
  value       = aws_iam_saml_provider.vpn_self_service.name
}
