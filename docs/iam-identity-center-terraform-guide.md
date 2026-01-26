# IAM Identity Center Terraform管理ガイド

## 📋 概要

このドキュメントは、IAM Identity CenterのリソースをTerraformで管理するための手順を説明します。

### Terraform管理対象

- ✅ Identity Storeグループ（VPN-Users）
- ✅ グループメンバーシップ（ユーザーのグループへの追加）

### 手動管理対象

- ⚠️ IAM Identity Centerの有効化
- ⚠️ SAML Applicationの作成
- ⚠️ ユーザーの作成
- ⚠️ SAMLメタデータのダウンロード

---

## 🚀 デプロイフロー

```
【手動作業】
1. IAM Identity Centerの有効化
   ↓
2. ユーザーの作成
   ↓
3. SAML Applicationの作成（2個）
   ↓
4. SAMLメタデータのダウンロード
   ↓
【Terraform自動化】
5. VPN-Usersグループの作成
   ↓
6. ユーザーのグループへの追加
   ↓
7. VPNエンドポイントのデプロイ
```

---

## 📝 手順1: IAM Identity Centerの有効化（手動）

### 1.1 有効化

```bash
# AWS Management Consoleで実施
# 1. IAM Identity Centerに移動
# 2. "Enable" ボタンをクリック
# 3. リージョンを選択（ap-northeast-1）
# 4. 有効化完了を待つ（数分かかります）
```

### 1.2 Identity Store IDの確認

```bash
# AWS CLIで確認
aws sso-admin list-instances

# 出力例:
# {
#     "Instances": [
#         {
#             "InstanceArn": "arn:aws:sso:::instance/ssoins-xxxxxxxxxxxxxxxxxx",
#             "IdentityStoreId": "d-xxxxxxxxxx"
#         }
#     ]
# }
```

**メモ**: Identity Store IDは自動的にTerraformで取得されます。

---

## 📝 手順2: ユーザーの作成（手動）

### 2.1 ユーザーの作成

```bash
# AWS Management Consoleで実施
# 1. IAM Identity Center > Users
# 2. "Add user" をクリック
# 3. ユーザー情報を入力:
#    - Username: user1@example.com
#    - Email: user1@example.com
#    - First name: User
#    - Last name: One
# 4. "Next" をクリック
# 5. グループは後でTerraformで追加するため、スキップ
# 6. "Add user" をクリック
```

### 2.2 ユーザーIDの取得

```bash
# AWS CLIでユーザーIDを取得
aws identitystore list-users \
  --identity-store-id d-xxxxxxxxxx \
  --filters AttributePath=UserName,AttributeValue=user1@example.com

# 出力例:
# {
#     "Users": [
#         {
#             "UserId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#             "UserName": "user1@example.com",
#             "DisplayName": "User One",
#             "Emails": [
#                 {
#                     "Value": "user1@example.com",
#                     "Type": "work",
#                     "Primary": true
#                 }
#             ]
#         }
#     ]
# }
```

**重要**: `UserId`をメモしてください。Terraformで使用します。

### 2.3 複数ユーザーのIDを一括取得

```bash
# すべてのユーザーIDを取得
aws identitystore list-users \
  --identity-store-id d-xxxxxxxxxx \
  --query 'Users[*].[UserId,UserName]' \
  --output table

# 出力例:
# ----------------------------------------
# |            ListUsers                 |
# +--------------------------------------+
# |  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|  user1@example.com
# |  yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy|  user2@example.com
# +--------------------------------------+
```

---

## 📝 手順3: SAML Applicationの作成（手動）

詳細は `docs/iam-identity-center-setup.md` を参照してください。

### 3.1 VPN Client Application

```bash
# AWS Management Consoleで実施
# 1. IAM Identity Center > Applications
# 2. "Add application" をクリック
# 3. "Add custom SAML 2.0 application" を選択
# 4. 設定:
#    - Display name: VPN Client
#    - Application ACS URL: http://127.0.0.1:35001
#    - Application SAML audience: urn:amazon:webservices:clientvpn
# 5. Attribute Mappings:
#    - Subject: ${user:email} (emailAddress)
#    - Name: ${user:email} (unspecified)
#    - FirstName: ${user:givenName} (unspecified)
#    - LastName: ${user:familyName} (unspecified)
#    - memberOf: ${user:groups} (unspecified)
# 6. "Submit" をクリック
```

### 3.2 VPN Self-Service Application

```bash
# 同様の手順で作成
# 設定:
#    - Display name: VPN Client Self Service
#    - Application Start URL: https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml
#    - Application ACS URL: https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml
```

---

## 📝 手順4: SAMLメタデータのダウンロード（手動）

### 4.1 VPN Client メタデータ

```bash
# AWS Management Consoleで実施
# 1. Applications > VPN Client を選択
# 2. "Actions" > "Edit attribute mappings" をクリック
# 3. ページ下部の "IAM Identity Center metadata" セクション
# 4. "IAM Identity Center SAML metadata file" をクリックしてダウンロード
# 5. ファイル名を vpn-client-metadata.xml に変更
# 6. metadata/ ディレクトリに保存
```

### 4.2 VPN Self-Service メタデータ

```bash
# 同様の手順で実施
# ファイル名: vpn-self-service-metadata.xml
```

### 4.3 確認

```bash
# メタデータファイルが存在することを確認
ls -la metadata/

# 期待される出力:
# vpn-client-metadata.xml
# vpn-self-service-metadata.xml
```

---

## 📝 手順5: Terraform設定（自動化）

### 5.1 terraform.tfvarsの設定

```bash
# terraform/terraform.tfvars を編集
nano terraform/terraform.tfvars
```

```hcl
# IAM Identity Center Configuration
# ユーザーIDのリスト（手順2.2で取得したID）
vpn_user_ids = [
  "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  # user1@example.com
  "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",  # user2@example.com
  "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"   # user3@example.com
]

# 既存のグループIDを使用する場合（オプション）
# iic_vpn_group_id = ""  # 空の場合、Terraformで作成したグループを使用

# Organization Configuration
organization_name = "YourOrganization"
vpn_domain        = "vpn.example.com"
```

### 5.2 Terraform初期化

```bash
cd terraform

# 初期化
terraform init

# フォーマット確認
terraform fmt

# 検証
terraform validate
```

### 5.3 実行計画の確認

```bash
# 実行計画を表示
terraform plan

# 確認ポイント:
# - aws_identitystore_group.vpn_users が作成される
# - aws_identitystore_group_membership.vpn_user_membership が作成される（ユーザー数分）
# - その他のVPNリソースが作成される
```

### 5.4 デプロイ実行

```bash
# デプロイ実行
terraform apply

# "yes" を入力して確認
```

---

## 📝 手順6: 既存リソースのImport（オプション）

既にVPN-Usersグループが存在する場合、Terraformにインポートできます。

### 6.1 既存グループのImport

```bash
# グループIDの取得
aws identitystore list-groups \
  --identity-store-id d-xxxxxxxxxx \
  --filters AttributePath=DisplayName,AttributeValue=VPN-Users

# 出力例:
# {
#     "Groups": [
#         {
#             "GroupId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
#             "DisplayName": "VPN-Users",
#             "Description": "AWS Client VPN Users"
#         }
#     ]
# }

# Terraformにインポート
terraform import aws_identitystore_group.vpn_users \
  d-xxxxxxxxxx/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
```

### 6.2 既存グループメンバーシップのImport

```bash
# グループメンバーシップIDの取得
aws identitystore list-group-memberships \
  --identity-store-id d-xxxxxxxxxx \
  --group-id aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa

# 出力例:
# {
#     "GroupMemberships": [
#         {
#             "MembershipId": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
#             "GroupId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
#             "MemberId": {
#                 "UserId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#             }
#         }
#     ]
# }

# Terraformにインポート（各ユーザーごと）
terraform import 'aws_identitystore_group_membership.vpn_user_membership["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]' \
  d-xxxxxxxxxx/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb
```

---

## 📝 手順7: SAML Applicationへのグループ割り当て（手動）

Terraformで作成したグループをSAML Applicationに割り当てます。

### 7.1 VPN Client Applicationへの割り当て

```bash
# AWS Management Consoleで実施
# 1. Applications > VPN Client を選択
# 2. "Assign users and groups" タブを選択
# 3. "Assign users and groups" ボタンをクリック
# 4. "Groups" タブを選択
# 5. "VPN-Users" グループを選択
# 6. "Assign users and groups" をクリック
```

### 7.2 VPN Self-Service Applicationへの割り当て

```bash
# 同様の手順で実施
```

---

## 🔍 確認手順

### 1. グループの確認

```bash
# Terraformで作成されたグループIDを確認
terraform output vpn_users_group_id

# AWS CLIで確認
aws identitystore describe-group \
  --identity-store-id d-xxxxxxxxxx \
  --group-id <group-id>
```

### 2. グループメンバーシップの確認

```bash
# グループメンバーを確認
aws identitystore list-group-memberships \
  --identity-store-id d-xxxxxxxxxx \
  --group-id <group-id>
```

### 3. SAML Applicationの確認

```bash
# AWS Management Consoleで確認
# 1. Applications > VPN Client
# 2. "Assigned users and groups" タブ
# 3. VPN-Users グループが割り当てられていることを確認
```

---

## 🔧 トラブルシューティング

### エラー1: Identity Store IDが見つからない

**エラーメッセージ**:
```
Error: error reading SSO Instances: no SSO instances found
```

**解決方法**:
```bash
# IAM Identity Centerが有効化されているか確認
aws sso-admin list-instances

# 有効化されていない場合、AWS Management Consoleで有効化
```

---

### エラー2: ユーザーIDが無効

**エラーメッセージ**:
```
Error: error creating IdentityStore Group Membership: ResourceNotFoundException
```

**解決方法**:
```bash
# ユーザーIDが正しいか確認
aws identitystore list-users \
  --identity-store-id d-xxxxxxxxxx

# terraform.tfvarsのvpn_user_idsを修正
```

---

### エラー3: グループが既に存在する

**エラーメッセージ**:
```
Error: error creating IdentityStore Group: ConflictException: Group with name VPN-Users already exists
```

**解決方法**:
```bash
# 既存グループをインポート（手順6.1を参照）
terraform import aws_identitystore_group.vpn_users \
  d-xxxxxxxxxx/<existing-group-id>
```

---

## 📊 リソース管理

### グループの更新

```bash
# グループの説明を変更
# terraform/iam_identity_center.tf を編集
resource "aws_identitystore_group" "vpn_users" {
  identity_store_id = local.identity_store_id
  display_name = "VPN-Users"
  description  = "AWS Client VPN Users - Updated Description"
}

# 適用
terraform apply
```

### ユーザーの追加

```bash
# terraform.tfvars に新しいユーザーIDを追加
vpn_user_ids = [
  "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  # user1
  "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",  # user2
  "new-user-id-here"                       # user3 (新規)
]

# 適用
terraform apply
```

### ユーザーの削除

```bash
# terraform.tfvars からユーザーIDを削除
vpn_user_ids = [
  "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  # user1
  # "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",  # user2 (削除)
]

# 適用
terraform apply
```

---

## 🔐 セキュリティベストプラクティス

### 1. ユーザーIDの保護

```bash
# terraform.tfvarsは.gitignoreに含まれています
# 絶対にGitにコミットしないでください

# 確認
cat .gitignore | grep tfvars
# 出力: *.tfvars
```

### 2. MFAの有効化

```bash
# すべてのVPNユーザーにMFAの登録を推奨
# ユーザーポータル: https://[your-domain].awsapps.com/start
```

### 3. 定期的なアクセスレビュー

```bash
# 月次でグループメンバーを確認
aws identitystore list-group-memberships \
  --identity-store-id d-xxxxxxxxxx \
  --group-id <group-id>
```

---

## 📚 参考資料

- [AWS IAM Identity Center User Guide](https://docs.aws.amazon.com/singlesignon/latest/userguide/)
- [Terraform AWS Provider - Identity Store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_group)
- [AWS CLI - Identity Store](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/identitystore/index.html)

---

**作成日**: 2025年1月25日  
**最終更新**: 2025年1月25日  
**バージョン**: 1.0.0
