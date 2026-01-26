# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = try(aws_vpc.main.id, null)
}

# Security Group Outputs
output "vpn_endpoint_security_group_id" {
  description = "Security Group ID for Client VPN endpoints"
  value       = try(aws_security_group.vpn_endpoint.id, null)
}

# NAT Gateway Outputs
output "nat_gateway_eip" {
  description = "NAT Gateway Elastic IP"
  value       = aws_eip.nat.public_ip
}

# CloudWatch Logs Outputs
output "vpn_pc_log_group" {
  description = "CloudWatch Log Group for PC VPN"
  value       = aws_cloudwatch_log_group.vpn_pc.name
}

output "vpn_mobile_log_group" {
  description = "CloudWatch Log Group for Mobile VPN"
  value       = aws_cloudwatch_log_group.vpn_mobile.name
}

# Certificate Outputs
output "vpn_server_cert_arn" {
  description = "VPN Server Certificate ARN"
  value       = aws_acm_certificate.vpn_server.arn
}

output "vpn_client_cert_arn" {
  description = "VPN Client Certificate ARN"
  value       = aws_acm_certificate.vpn_client.arn
}
