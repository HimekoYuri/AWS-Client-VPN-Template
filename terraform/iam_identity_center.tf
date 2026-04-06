# ============================================================================
# IAM Identity Center Configuration
# ============================================================================
# Requirements: 1.1, 1.2, 1.3
# ============================================================================

data "aws_ssoadmin_instances" "main" {}

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.main.arns)[0]
}

# VPN-Usersグループ
resource "aws_identitystore_group" "vpn_users" {
  identity_store_id = local.identity_store_id
  display_name      = "VPN-Users"
  description       = "AWS Client VPN Users - Managed by Terraform"
}

# グループメンバーシップ
resource "aws_identitystore_group_membership" "vpn_user_membership" {
  for_each = toset(var.vpn_user_ids)

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.vpn_users.group_id
  member_id         = each.value
}
