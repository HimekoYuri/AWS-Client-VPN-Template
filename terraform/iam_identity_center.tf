# ============================================================================
# IAM Identity Center Configuration
# ============================================================================
# このファイルは、IAM Identity Centerのグループとユーザー管理を定義します。
# 
# 【重要】前提条件:
# 1. IAM Identity Centerが有効化されていること（手動操作）
# 2. Identity Store IDが取得されていること
# 3. SAML Applicationが作成されていること（手動操作）
#
# 【Terraform管理対象】
# - Identity Storeグループ
# - グループメンバーシップ
#
# 【手動管理対象】
# - IAM Identity Centerの有効化
# - SAML Applicationの作成
# - ユーザーの作成（既存ユーザーをImport）
#
# Requirements: 1.1, 1.2, 1.3
# ============================================================================

# ----------------------------------------------------------------------------
# Data Sources - 既存リソースの参照
# ----------------------------------------------------------------------------

# IAM Identity Center インスタンスの取得
data "aws_ssoadmin_instances" "main" {}

# Identity Store IDの取得
locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.main.arns)[0]
}

# ----------------------------------------------------------------------------
# Identity Store Group - VPN Users
# ----------------------------------------------------------------------------
# VPN接続を許可するユーザーグループ
# このグループに所属するユーザーのみがVPN接続可能
# ----------------------------------------------------------------------------

resource "aws_identitystore_group" "vpn_users" {
  identity_store_id = local.identity_store_id

  display_name = "VPN-Users"
  description  = "AWS Client VPN Users - Managed by Terraform"
}

# ----------------------------------------------------------------------------
# Group Membership - ユーザーのグループへの追加
# ----------------------------------------------------------------------------
# 既存ユーザーをVPN-Usersグループに追加
# 
# 【使用方法】
# 1. AWS Management Consoleでユーザーを作成
# 2. ユーザーIDを取得
# 3. terraform.tfvarsでvpn_user_idsを設定
# 4. terraform applyで自動的にグループに追加
#
# 【ユーザーIDの取得方法】
# AWS CLI:
#   aws identitystore list-users \
#     --identity-store-id <identity-store-id> \
#     --filters AttributePath=UserName,AttributeValue=<username>
#
# または、AWS Management Console:
#   IAM Identity Center > Users > ユーザーを選択 > User ID をコピー
# ----------------------------------------------------------------------------

resource "aws_identitystore_group_membership" "vpn_user_membership" {
  for_each = toset(var.vpn_user_ids)

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.vpn_users.group_id
  member_id         = each.value
}

# ----------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------

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

output "vpn_users_group_name" {
  description = "VPN Users Group Name"
  value       = aws_identitystore_group.vpn_users.display_name
}

# ----------------------------------------------------------------------------
# 使用例とImport手順
# ----------------------------------------------------------------------------
# 
# 【既存ユーザーのImport手順】
# 
# 1. ユーザーIDの取得:
#    aws identitystore list-users \
#      --identity-store-id <identity-store-id>
# 
# 2. terraform.tfvarsに追加:
#    vpn_user_ids = [
#      "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  # user1
#      "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"   # user2
#    ]
# 
# 3. Terraform適用:
#    terraform plan
#    terraform apply
# 
# 【既存グループのImport手順】
# 
# 既にVPN-Usersグループが存在する場合:
# 
# 1. グループIDの取得:
#    aws identitystore list-groups \
#      --identity-store-id <identity-store-id> \
#      --filters AttributePath=DisplayName,AttributeValue=VPN-Users
# 
# 2. Terraformにインポート:
#    terraform import aws_identitystore_group.vpn_users \
#      <identity-store-id>/<group-id>
# 
# 【SAML Applicationの手動作成】
# 
# SAML ApplicationはTerraformで管理できないため、手動で作成:
# 1. IAM Identity Center > Applications > Add application
# 2. Custom SAML 2.0 application を選択
# 3. 詳細は docs/iam-identity-center-setup.md を参照
# 
# 【SAMLメタデータのダウンロード】
# 
# 1. Applications > VPN Client > Actions > Edit attribute mappings
# 2. IAM Identity Center SAML metadata file をダウンロード
# 3. metadata/vpn-client-metadata.xml として保存
# 
# ============================================================================
