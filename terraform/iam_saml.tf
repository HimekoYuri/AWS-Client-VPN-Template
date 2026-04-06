# ============================================================================
# IAM SAML Identity Provider Configuration
# ============================================================================
# Requirements: 1.4, 2.1
# IAM Identity Center（旧AWS SSO）と連携し、SAML 2.0認証を実現
# ============================================================================

# VPN Client用 SAML Identity Provider
resource "aws_iam_saml_provider" "vpn_client" {
  name                   = "aws-client-vpn"
  saml_metadata_document = file("${path.module}/../metadata/vpn-client-saml-metadata.xml")

  tags = {
    Name    = "aws-client-vpn-saml-provider"
    Purpose = "Client VPN SAML Authentication"
  }
}

# VPN Self-Service Portal用 SAML Identity Provider
resource "aws_iam_saml_provider" "vpn_self_service" {
  name                   = "aws-client-vpn-self-service"
  saml_metadata_document = file("${path.module}/../metadata/vpn-client-saml-metadata.xml")

  tags = {
    Name    = "aws-client-vpn-self-service-saml-provider"
    Purpose = "Client VPN Self-Service Portal SAML Authentication"
  }
}
