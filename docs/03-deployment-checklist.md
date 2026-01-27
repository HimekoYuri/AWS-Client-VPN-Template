# AWS Client VPN デプロイチェックリスト

## 📋 デプロイ前の確認

### ✅ 完了済み項目

- [x] IAM Identity Center有効化済み
  - Identity Store ID: `d-9067dc092d`
  - SSO Instance: `ssoins-72233d29e4c9ef9b`
  
- [x] ユーザー確認済み
  - User ID: `b448d448-4061-7023-29b0-8901d5628601`
  - Username: `y-kalen`
  
- [x] 証明書生成済み
  - `certs/ca.crt`
  - `certs/ca.key`
  - `certs/server.crt`
  - `certs/server.key`
  - `certs/client1.vpn.example.com.crt`
  - `certs/client1.vpn.example.com.key`

- [x] terraform.tfvars設定済み
  - `vpn_user_ids` = `["b448d448-4061-7023-29b0-8901d5628601"]`
  - `iic_vpn_group_id` = `""`（新規グループ作成）

---

## ⚠️ デプロイ前に必要な作業

### 1. SAML Applicationの作成（手動）

#### 1.1 VPN Client Application

```bash
# AWS Management Consoleで実施
# URL: https://console.aws.amazon.com/singlesignon/

# 手順:
# 1. IAM Identity Center > Applications
# 2. "Add application" をクリック
# 3. "Add custom SAML 2.0 application" を選択
# 4. 以下を設定:
```

**設定値**:
```
Display name: VPN Client
Description: AWS Client VPN SAML Authentication
Application ACS URL: http://127.0.0.1:35001
Application SAML audience: urn:amazon:webservices:clientvpn
```

**Attribute Mappings**:
| Application Attribute | IAM Identity Center Attribute | Format |
|----------------------|------------------------------|--------|
| `Subject` | `${user:email}` | `emailAddress` |
| `Name` | `${user:email}` | `unspecified` |
| `FirstName` | `${user:givenName}` | `unspecified` |
| `LastName` | `${user:familyName}` | `unspecified` |
| `memberOf` | `${user:groups}` | `unspecified` |

#### 1.2 VPN Self-Service Application

```bash
# 同様の手順で作成
```

**設定値**:
```
Display name: VPN Client Self Service
Description: AWS Client VPN Self-Service Portal
Application Start URL: https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml
Application ACS URL: https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml
Application SAML audience: urn:amazon:webservices:clientvpn
```

**Attribute Mappings**: VPN Clientと同じ

---

### 2. SAMLメタデータのダウンロード（手動）

#### 2.1 VPN Client メタデータ

```bash
# AWS Management Consoleで実施
# 1. Applications > VPN Client を選択
# 2. "Actions" > "Edit attribute mappings" をクリック
# 3. ページ下部の "IAM Identity Center metadata" セクション
# 4. "IAM Identity Center SAML metadata file" をクリックしてダウンロード
```

**保存先**: `metadata/vpn-client-metadata.xml`

#### 2.2 VPN Self-Service メタデータ

```bash
# 同様の手順で実施
```

**保存先**: `metadata/vpn-self-service-metadata.xml`

#### 2.3 確認

```bash
# Windowsの場合
dir metadata\

# Linux/macOSの場合
ls -la metadata/

# 期待される出力:
# vpn-client-metadata.xml
# vpn-self-service-metadata.xml
```

---

## 🚀 デプロイ手順

### ステップ1: AWS認証

```bash
# ターミナルを開く
cd /mnt/d/CloudDrive/Google/Client-VPN-test/terraform

# AWS認証
aws login

# 認証確認
aws sts get-caller-identity

# 期待される出力:
# {
#     "UserId": "...",
#     "Account": "620360464874",
#     "Arn": "arn:aws:sts::620360464874:assumed-role/AWSReservedSSO_AdministratorAccess_61485ef71d1c3c46/y-kalen"
# }
```

---

### ステップ2: 証明書とメタデータの確認

```bash
# 証明書ファイルの確認
ls -la ../certs/

# 期待される出力:
# ca.crt
# ca.key
# server.crt
# server.key
# client1.vpn.example.com.crt
# client1.vpn.example.com.key

# SAMLメタデータの確認
ls -la ../metadata/

# 期待される出力:
# vpn-client-metadata.xml
# vpn-self-service-metadata.xml
```

**⚠️ 重要**: ファイルが存在しない場合は、上記の「デプロイ前に必要な作業」を完了してください。

---

### ステップ3: Terraform初期化

```bash
# Terraformディレクトリに移動
cd /mnt/d/CloudDrive/Google/Client-VPN-test/terraform

# 初期化
terraform init

# 期待される出力:
# Terraform has been successfully initialized!
```

---

### ステップ4: 実行計画の確認

```bash
# 実行計画を表示
terraform plan

# 確認ポイント:
# ✅ aws_identitystore_group.vpn_users が作成される
# ✅ aws_identitystore_group_membership.vpn_user_membership["b448d448-4061-7023-29b0-8901d5628601"] が作成される
# ✅ aws_vpc.main が作成される
# ✅ aws_ec2_client_vpn_endpoint.pc が作成される
# ✅ aws_ec2_client_vpn_endpoint.mobile が作成される
# ✅ 合計約43リソースが作成される
```

---

### ステップ5: デプロイ実行

```bash
# デプロイ実行
terraform apply

# "yes" を入力して確認

# デプロイ時間: 約10-15分
```

**デプロイ中の表示例**:
```
aws_identitystore_group.vpn_users: Creating...
aws_identitystore_group.vpn_users: Creation complete after 2s
aws_identitystore_group_membership.vpn_user_membership["b448d448-4061-7023-29b0-8901d5628601"]: Creating...
aws_vpc.main: Creating...
...
Apply complete! Resources: 43 added, 0 changed, 0 destroyed.
```

---

### ステップ6: デプロイ結果の確認

```bash
# 出力値を表示
terraform output

# 期待される出力:
# identity_store_id = "d-9067dc092d"
# nat_gateway_eip = "xx.xx.xx.xx"
# vpc_id = "vpc-xxxxxxxxxxxxxxxxx"
# vpn_mobile_dns_name = "cvpn-endpoint-xxxxx.prod.clientvpn.ap-northeast-1.amazonaws.com"
# vpn_mobile_endpoint_id = "cvpn-endpoint-xxxxx"
# vpn_pc_endpoint_id = "cvpn-endpoint-xxxxx"
# vpn_pc_self_service_url = "https://self-service.clientvpn.amazonaws.com/endpoints/cvpn-endpoint-xxxxx"
# vpn_users_group_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# vpn_users_group_name = "VPN-Users"
```

---

### ステップ7: 作成されたグループIDの確認

```bash
# Terraformで作成されたVPN-UsersグループIDを確認
terraform output vpn_users_group_id

# 出力例: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# AWS CLIでも確認
aws identitystore list-groups \
  --identity-store-id d-9067dc092d \
  --filters AttributePath=DisplayName,AttributeValue=VPN-Users

# グループメンバーを確認
aws identitystore list-group-memberships \
  --identity-store-id d-9067dc092d \
  --group-id $(terraform output -raw vpn_users_group_id)
```

---

## 📝 デプロイ後の作業

### 1. SAML ApplicationへのグループAssign（手動）

#### 1.1 VPN Client Applicationへの割り当て

```bash
# AWS Management Consoleで実施
# 1. IAM Identity Center > Applications
# 2. "VPN Client" を選択
# 3. "Assign users and groups" タブを選択
# 4. "Assign users and groups" ボタンをクリック
# 5. "Groups" タブを選択
# 6. "VPN-Users" グループを選択（Terraformで作成されたグループ）
# 7. "Assign users and groups" をクリック
```

#### 1.2 VPN Self-Service Applicationへの割り当て

```bash
# 同様の手順で実施
# "VPN Client Self Service" アプリケーションに "VPN-Users" グループを割り当て
```

---

### 2. VPN接続テスト

#### 2.1 Self-Service Portalへのアクセス

```bash
# Self-Service Portal URLを取得
terraform output vpn_pc_self_service_url

# ブラウザでURLを開く
# 例: https://self-service.clientvpn.amazonaws.com/endpoints/cvpn-endpoint-xxxxx
```

#### 2.2 IAM Identity Centerでログイン

```bash
# 1. Self-Service Portal URLにアクセス
# 2. IAM Identity Centerのログイン画面が表示される
# 3. ユーザー名: y-kalen
# 4. パスワード: （IAM Identity Centerで設定したパスワード）
# 5. MFAコード: （MFA有効の場合）
# 6. VPN設定ファイルをダウンロード
```

#### 2.3 AWS VPN Clientで接続

```bash
# 1. AWS VPN Clientをインストール
#    https://aws.amazon.com/vpn/client-vpn-download/

# 2. ダウンロードした設定ファイルをインポート
# 3. "Connect" をクリック
# 4. 接続成功を確認
```

#### 2.4 静的IPの確認

```bash
# VPN接続後、送信元IPを確認
curl https://api.ipify.org

# terraform outputで表示されたElastic IPと一致することを確認
terraform output nat_gateway_eip
```

---

## ✅ 完了チェックリスト

### デプロイ前
- [ ] IAM Identity Center有効化済み
- [ ] ユーザー作成済み
- [ ] 証明書生成済み
- [ ] SAML Application作成済み（2個）
- [ ] SAMLメタデータダウンロード済み（2個）
- [ ] terraform.tfvars設定済み

### デプロイ中
- [ ] AWS認証完了
- [ ] terraform init実行完了
- [ ] terraform plan確認完了
- [ ] terraform apply実行完了
- [ ] エラーなく完了

### デプロイ後
- [ ] terraform output確認完了
- [ ] VPN-Usersグループ作成確認
- [ ] ユーザーがグループに追加確認
- [ ] SAML ApplicationにグループAssign完了
- [ ] VPN接続テスト完了（PC用）
- [ ] 静的IP確認完了

---

## 🔧 トラブルシューティング

### エラー1: SAMLメタデータが見つからない

**エラーメッセージ**:
```
Error: Error reading file ../metadata/vpn-client-metadata.xml: no such file or directory
```

**解決方法**:
1. SAML Applicationを作成
2. SAMLメタデータをダウンロード
3. `metadata/`ディレクトリに配置
4. `terraform apply`を再実行

---

### エラー2: ユーザーIDが無効

**エラーメッセージ**:
```
Error: error creating IdentityStore Group Membership: ResourceNotFoundException
```

**解決方法**:
```bash
# ユーザーIDを再確認
aws identitystore list-users \
  --identity-store-id d-9067dc092d

# terraform.tfvarsのvpn_user_idsを修正
# 正しいUser IDに更新
```

---

### エラー3: グループAssignができない

**症状**: SAML Applicationにグループが表示されない

**解決方法**:
```bash
# グループが作成されているか確認
terraform output vpn_users_group_id

# AWS Management Consoleでグループを確認
# IAM Identity Center > Groups > VPN-Users

# 数分待ってから再度試す（同期に時間がかかる場合があります）
```

---

## 📞 サポート

問題が発生した場合:
1. `docs/troubleshooting.md`を確認
2. `docs/existing-iic-setup.md`を確認
3. CloudWatch Logsでエラーログを確認
4. 社内のインフラチームに連絡

---

**作成日**: 2025年1月25日  
**最終更新**: 2025年1月25日  
**バージョン**: 1.0.0
