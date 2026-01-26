# 既存IAM Identity Center使用ガイド

## 📋 概要

既に有効化されているIAM Identity Centerインスタンスを使用してClient VPNをデプロイする手順です。

### 既存IIC情報

- **Identity Store ID**: `d-9067dc092d`
- **SSO Instance**: `ssoins-72233d29e4c9ef9b`
- **AWS Access Portal**: `https://d-9067dc092d.awsapps.com/start`

---

## 🔍 ステップ1: 既存リソースの確認

### 1.1 既存ユーザーの確認

```bash
# すべてのユーザーを表示
aws identitystore list-users \
  --identity-store-id d-9067dc092d \
  --query 'Users[*].[UserId,UserName,DisplayName]' \
  --output table

# 出力例:
# ---------------------------------------------------------------
# |                        ListUsers                            |
# +--------------------------------------+-----------------------+
# |  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|  user1@example.com   |
# |  yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy|  user2@example.com   |
# +--------------------------------------+-----------------------+
```

### 1.2 既存グループの確認

```bash
# すべてのグループを表示
aws identitystore list-groups \
  --identity-store-id d-9067dc092d \
  --query 'Groups[*].[GroupId,DisplayName,Description]' \
  --output table

# VPN用グループが既に存在するか確認
aws identitystore list-groups \
  --identity-store-id d-9067dc092d \
  --filters AttributePath=DisplayName,AttributeValue=VPN-Users
```

---

## 🎯 ステップ2: デプロイ方法の選択

### シナリオA: 既存グループを使用

**条件**: VPN用のグループが既に存在し、ユーザーも追加済み

**メリット**:
- 既存の設定を活用
- ユーザー管理が不要
- 最小限の変更

**手順**: [シナリオA手順](#シナリオa-既存グループを使用する手順)へ

### シナリオB: 新規グループを作成

**条件**: VPN専用の新しいグループを作成したい

**メリット**:
- VPN専用のグループ管理
- Terraformで完全管理
- 柔軟なユーザー追加・削除

**手順**: [シナリオB手順](#シナリオb-新規グループを作成する手順)へ

---

## 📝 シナリオA: 既存グループを使用する手順

### A-1. 既存グループIDの取得

```bash
# VPN用グループのIDを取得
aws identitystore list-groups \
  --identity-store-id d-9067dc092d \
  --filters AttributePath=DisplayName,AttributeValue=VPN-Users \
  --query 'Groups[0].GroupId' \
  --output text

# 出力例: aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
```

### A-2. グループメンバーの確認

```bash
# グループに所属するユーザーを確認
aws identitystore list-group-memberships \
  --identity-store-id d-9067dc092d \
  --group-id aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
```

### A-3. SAML Applicationの作成

詳細は `docs/iam-identity-center-setup.md` を参照してください。

**重要な設定**:

#### VPN Client Application
- Display name: `VPN Client`
- Application ACS URL: `http://127.0.0.1:35001`
- Application SAML audience: `urn:amazon:webservices:clientvpn`

#### VPN Self-Service Application
- Display name: `VPN Client Self Service`
- Application Start URL: `https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml`

### A-4. SAMLメタデータのダウンロード

```bash
# AWS Management Consoleで実施
# 1. Applications > VPN Client > Actions > Edit attribute mappings
# 2. "IAM Identity Center SAML metadata file" をダウンロード
# 3. metadata/vpn-client-metadata.xml として保存

# 同様に Self-Service用もダウンロード
# 4. metadata/vpn-self-service-metadata.xml として保存
```

### A-5. terraform.tfvarsの設定

```bash
cd terraform
nano terraform.tfvars
```

```hcl
# 既存グループIDを使用
iic_vpn_group_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

# ユーザーIDは空（既にグループに所属しているため）
vpn_user_ids = []

# Organization Configuration
organization_name = "YourOrganization"
vpn_domain        = "vpn.example.com"
```

### A-6. Terraformデプロイ

```bash
# 初期化
terraform init

# 実行計画の確認
terraform plan

# デプロイ
terraform apply
```

### A-7. SAML Applicationへのグループ割り当て

```bash
# AWS Management Consoleで実施
# 1. Applications > VPN Client
# 2. "Assign users and groups" タブ
# 3. "Assign users and groups" ボタンをクリック
# 4. "Groups" タブで既存のVPN-Usersグループを選択
# 5. "Assign users and groups" をクリック

# 同様に Self-Service Applicationにも割り当て
```

---

## 📝 シナリオB: 新規グループを作成する手順

### B-1. VPN用ユーザーIDの取得

```bash
# VPN接続を許可するユーザーのIDを取得
aws identitystore list-users \
  --identity-store-id d-9067dc092d \
  --query 'Users[*].[UserId,UserName]' \
  --output table

# 特定のユーザーを検索
aws identitystore list-users \
  --identity-store-id d-9067dc092d \
  --filters AttributePath=UserName,AttributeValue=user1@example.com \
  --query 'Users[0].UserId' \
  --output text
```

### B-2. SAML Applicationの作成

シナリオAと同じ手順で作成します。

### B-3. SAMLメタデータのダウンロード

シナリオAと同じ手順でダウンロードします。

### B-4. terraform.tfvarsの設定

```bash
cd terraform
nano terraform.tfvars
```

```hcl
# 新規グループを作成（Terraformで自動作成）
iic_vpn_group_id = ""

# VPN接続を許可するユーザーIDのリスト
vpn_user_ids = [
  "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  # user1@example.com
  "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",  # user2@example.com
  "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"   # user3@example.com
]

# Organization Configuration
organization_name = "YourOrganization"
vpn_domain        = "vpn.example.com"
```

### B-5. Terraformデプロイ

```bash
# 初期化
terraform init

# 実行計画の確認
terraform plan

# 確認ポイント:
# - aws_identitystore_group.vpn_users が作成される
# - aws_identitystore_group_membership.vpn_user_membership が作成される

# デプロイ
terraform apply
```

### B-6. 作成されたグループIDの確認

```bash
# Terraformで作成されたグループIDを確認
terraform output vpn_users_group_id

# 出力例: bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb
```

### B-7. SAML Applicationへのグループ割り当て

```bash
# AWS Management Consoleで実施
# 1. Applications > VPN Client
# 2. "Assign users and groups" タブ
# 3. "Assign users and groups" ボタンをクリック
# 4. "Groups" タブで "VPN-Users" グループを選択
# 5. "Assign users and groups" をクリック

# 同様に Self-Service Applicationにも割り当て
```

---

## 🔍 ステップ3: デプロイ後の確認

### 3.1 VPCとネットワークの確認

```bash
# VPCが作成されたことを確認
terraform output vpc_id

# NAT GatewayのElastic IPを確認
terraform output nat_gateway_eip
```

### 3.2 VPNエンドポイントの確認

```bash
# PC用VPNエンドポイントIDを確認
terraform output vpn_pc_endpoint_id

# Self-Service Portal URLを確認
terraform output vpn_pc_self_service_url
```

### 3.3 AWS Management Consoleで確認

```bash
# 1. VPC > Client VPN Endpoints
# 2. 2個のエンドポイントが作成されていることを確認
#    - client-vpn-pc-endpoint (SAML認証)
#    - client-vpn-mobile-endpoint (証明書認証)
# 3. ステータスが "available" になっていることを確認
```

---

## 🧪 ステップ4: VPN接続テスト

### 4.1 Self-Service Portalへのアクセス

```bash
# Self-Service Portal URLをブラウザで開く
terraform output vpn_pc_self_service_url

# 出力例:
# https://self-service.clientvpn.amazonaws.com/endpoints/cvpn-endpoint-xxxxx
```

### 4.2 IAM Identity Centerでログイン

```bash
# 1. Self-Service Portal URLにアクセス
# 2. IAM Identity Centerのログイン画面が表示される
# 3. ユーザー名とパスワードを入力
# 4. MFAコードを入力（MFA有効の場合）
# 5. VPN設定ファイルをダウンロード
```

### 4.3 AWS VPN Clientで接続

```bash
# 1. AWS VPN Clientをインストール
# 2. ダウンロードした設定ファイルをインポート
# 3. "Connect" をクリック
# 4. 接続成功を確認
```

### 4.4 静的IPの確認

```bash
# VPN接続後、送信元IPを確認
curl https://api.ipify.org

# terraform outputで表示されたElastic IPと一致することを確認
terraform output nat_gateway_eip
```

---

## 🔧 トラブルシューティング

### エラー1: グループが見つからない

**症状**: SAML Applicationにグループが表示されない

**解決方法**:
```bash
# グループが正しく作成されているか確認
aws identitystore list-groups \
  --identity-store-id d-9067dc092d \
  --filters AttributePath=DisplayName,AttributeValue=VPN-Users

# Terraformで作成した場合
terraform output vpn_users_group_id
```

---

### エラー2: ユーザーがグループに所属していない

**症状**: VPN接続時に認証エラー

**解決方法**:
```bash
# グループメンバーシップを確認
aws identitystore list-group-memberships \
  --identity-store-id d-9067dc092d \
  --group-id <group-id>

# ユーザーが所属していない場合、terraform.tfvarsに追加
vpn_user_ids = [
  "existing-user-id",
  "new-user-id"  # 追加
]

# 適用
terraform apply
```

---

### エラー3: SAMLメタデータが古い

**症状**: SAML認証に失敗する

**解決方法**:
```bash
# 最新のSAMLメタデータを再ダウンロード
# 1. Applications > VPN Client > Actions > Edit attribute mappings
# 2. "IAM Identity Center SAML metadata file" を再ダウンロード
# 3. metadata/vpn-client-metadata.xml を上書き

# Terraformを再適用
terraform apply
```

---

## 📊 ユーザー管理

### ユーザーの追加（シナリオB）

```bash
# 新しいユーザーIDを取得
aws identitystore list-users \
  --identity-store-id d-9067dc092d \
  --filters AttributePath=UserName,AttributeValue=newuser@example.com \
  --query 'Users[0].UserId' \
  --output text

# terraform.tfvarsに追加
vpn_user_ids = [
  "existing-user-id-1",
  "existing-user-id-2",
  "new-user-id"  # 追加
]

# 適用
terraform apply
```

### ユーザーの削除（シナリオB）

```bash
# terraform.tfvarsから削除
vpn_user_ids = [
  "existing-user-id-1",
  # "existing-user-id-2",  # 削除
]

# 適用
terraform apply
```

---

## 🔐 セキュリティ推奨事項

### 1. MFAの有効化

```bash
# すべてのVPNユーザーにMFAの登録を推奨
# ユーザーポータル: https://d-9067dc092d.awsapps.com/start

# ユーザーに案内:
# 1. ユーザーポータルにログイン
# 2. 右上のユーザー名 > MFA devices
# 3. Register MFA device
# 4. 認証アプリでQRコードをスキャン
```

### 2. 定期的なアクセスレビュー

```bash
# 月次でグループメンバーを確認
aws identitystore list-group-memberships \
  --identity-store-id d-9067dc092d \
  --group-id <group-id> \
  --query 'GroupMemberships[*].MemberId.UserId' \
  --output table
```

### 3. CloudWatch Logsの監視

```bash
# VPN接続ログを確認
aws logs tail /aws/clientvpn/pc --follow

# 異常なアクセスパターンを監視
```

---

## 📚 次のステップ

1. ✅ VPN接続テスト完了
2. ⏭️ スマホ用VPN設定（`docs/vpn-connection-mobile.md`）
3. ⏭️ 運用監視の設定
4. ⏭️ バックアップとディザスタリカバリ計画

---

**作成日**: 2025年1月25日  
**最終更新**: 2025年1月25日  
**バージョン**: 1.0.0
