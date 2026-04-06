# ============================================================================
# Outputs
# ============================================================================

# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# Subnets
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# Security Group
output "vpn_endpoint_security_group_id" {
  description = "Security Group ID for Client VPN endpoints"
  value       = aws_security_group.vpn_endpoint.id
}

# NAT Gateway
output "nat_gateway_eips" {
  description = "NAT Gateway Elastic IPs"
  value       = aws_eip.nat[*].public_ip
}

# VPN Endpoints
output "vpn_pc_endpoint_id" {
  description = "PC VPN Endpoint ID"
  value       = aws_ec2_client_vpn_endpoint.pc.id
}

output "vpn_mobile_endpoint_id" {
  description = "Mobile VPN Endpoint ID"
  value       = aws_ec2_client_vpn_endpoint.mobile.id
}

output "vpn_pc_dns_name" {
  description = "PC VPN Endpoint DNS name"
  value       = aws_ec2_client_vpn_endpoint.pc.dns_name
}

output "vpn_mobile_dns_name" {
  description = "Mobile VPN Endpoint DNS name"
  value       = aws_ec2_client_vpn_endpoint.mobile.dns_name
}

# CloudWatch Logs
output "vpn_pc_log_group" {
  description = "CloudWatch Log Group for PC VPN"
  value       = aws_cloudwatch_log_group.vpn_pc.name
}

output "vpn_mobile_log_group" {
  description = "CloudWatch Log Group for Mobile VPN"
  value       = aws_cloudwatch_log_group.vpn_mobile.name
}

# Certificates
output "vpn_server_cert_arn" {
  description = "VPN Server Certificate ARN"
  value       = aws_acm_certificate.vpn_server.arn
  sensitive   = true
}

output "vpn_client_cert_arn" {
  description = "VPN Client Certificate ARN"
  value       = aws_acm_certificate.vpn_client.arn
  sensitive   = true
}

# SAML Providers
output "vpn_client_saml_provider_arn" {
  description = "VPN Client SAML Identity Provider ARN"
  value       = aws_iam_saml_provider.vpn_client.arn
}

output "vpn_self_service_saml_provider_arn" {
  description = "VPN Self-Service Portal SAML Identity Provider ARN"
  value       = aws_iam_saml_provider.vpn_self_service.arn
}

# IAM Identity Center
output "identity_store_id" {
  description = "Identity Store ID"
  value       = local.identity_store_id
}

output "sso_instance_arn" {
  description = "SSO Instance ARN"
  value       = local.sso_instance_arn
}

output "vpn_users_group_id" {
  description = "VPN Users Group ID"
  value       = aws_identitystore_group.vpn_users.group_id
}

# KMS (only when enabled)
output "logs_kms_key_arn" {
  description = "KMS Key ARN for CloudWatch Logs encryption"
  value       = local.logs_kms_key_arn
}

output "cloudtrail_kms_key_arn" {
  description = "KMS Key ARN for CloudTrail encryption"
  value       = local.cloudtrail_kms_key_arn
}
