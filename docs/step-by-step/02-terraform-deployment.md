# ステップ2: Terraformデプロイ

## 📋 このステップでやること

Terraformを使用してAWS Client VPNインフラストラクチャをデプロイします。

**所要時間**: 約10-15分

## 🎯 作成されるリソース

- VPN-Usersグループ（Terraform自動作成）
- y-kalenユーザーをグループに追加
- VPC、サブネット、ゲートウェイ
- VPNエンドポイント2個（PC用、スマホ用）
- CloudWatch Logs、CloudTrail
- **合計約43リソース**

---

## 📝 パート1: AWS認証

### 1-1. ターミナルを開く

#### Windowsの場合

```
1. スタートメニューから「Ubuntu」または「WSL」を検索

2. WSL/Linuxターミナルを起動
```

#### Linux/macOSの場合

```
ターミナルを起動
```

### 1-2. プロジェクトディレクトリに移動

```bash
cd /mnt/d/CloudDrive/Google/Client-VPN-test/terraform
```

### 1-3. AWS認証

```bash
# AWS SSOでログイン
aws login
```

**ブラウザが開きます**:
```
1. ブラウザでAWS SSOログイン画面が表示される

2. ユーザー名とパスワードを入力

3. MFAコード（必要な場合）を入力

4. 「Allow」をクリック

5. ターミナルに戻る
```

### 1-4. 認証確認

```bash
# 認証情報を確認
aws sts get-caller-identity
```

**期待される出力**:
```json
{
    "UserId": "AROAJLUWOHFDR2BNQE36S:y-kalen",
    "Account": "620360464874",
    "Arn": "arn:aws:sts::620360464874:assumed-role/AWSReservedSSO_AdministratorAccess_61485ef71d1c3c46/y-kalen"
}
```

**✅ 確認ポイント**:
- Account: `620360464874`
- Arn に `y-kalen` が含まれている

---

## 📝 パート2: 証明書とメタデータの確認

### 2-1. 証明書ファイルの確認

```bash
# 証明書ファイルを確認
ls -la ../certs/
```

**期待される出力**:
```
ca.crt
ca.key
server.crt
server.key
client1.vpn.example.com.crt
client1.vpn.example.com.key
```

### 2-2. SAMLメタデータの確認

```bash
# SAMLメタデータを確認
ls -la ../metadata/
```

**期待される出力**:
```
vpn-client-metadata.xml
vpn-self-service-metadata.xml
```

### 2-3. terraform.tfvarsの確認

```bash
# terraform.tfvarsの内容を確認
cat terraform.tfvars
```

**期待される内容**:
```hcl
iic_vpn_group_id = ""
vpn_user_ids = [
  "b448d448-4061-7023-29b0-8901d5628601"
]
organization_name = "YourOrganization"
vpn_domain        = "vpn.example.com"
```

**⚠️ 重要**: ファイルが存在しない場合は、ステップ1に戻ってSAMLメタデータをダウンロードしてください。

---

## 📝 パート3: Terraform初期化

### 3-1. Terraform初期化

```bash
# Terraformを初期化
terraform init
```

**期待される出力**:
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
- Installed hashicorp/aws v5.x.x

Terraform has been successfully initialized!
```

**✅ 確認ポイント**:
- `Terraform has been successfully initialized!` が表示される
- エラーメッセージがない

### 3-2. Terraformフォーマット確認（オプション）

```bash
# コードフォーマットを確認
terraform fmt
```

### 3-3. Terraform検証

```bash
# 構文エラーをチェック
terraform validate
```

**期待される出力**:
```
Success! The configuration is valid.
```

---

## 📝 パート4: 実行計画の確認

### 4-1. 実行計画を表示

```bash
# 実行計画を表示
terraform plan
```

**出力が長いため、重要な部分を確認します**

### 4-2. 作成されるリソースの確認

**確認ポイント**:

#### Identity Store（IAM Identity Center）
```
# aws_identitystore_group.vpn_users will be created
+ resource "aws_identitystore_group" "vpn_users" {
    + display_name = "VPN-Users"
    + description  = "AWS Client VPN Users - Managed by Terraform"
  }

# aws_identitystore_group_membership.vpn_user_membership["b448d448-4061-7023-29b0-8901d5628601"] will be created
```

#### VPC とネットワーク
```
# aws_vpc.main will be created
+ resource "aws_vpc" "main" {
    + cidr_block = "192.168.0.0/16"
  }

# aws_subnet.public[0] will be created
# aws_subnet.public[1] will be created
# aws_subnet.private[0] will be created
# aws_subnet.private[1] will be created

# aws_nat_gateway.main will be created
# aws_eip.nat will be created
```

#### VPNエンドポイント
```
# aws_ec2_client_vpn_endpoint.pc will be created
+ resource "aws_ec2_client_vpn_endpoint" "pc" {
    + description = "Client VPN Endpoint for PC (SAML + MFA)"
  }

# aws_ec2_client_vpn_endpoint.mobile will be created
+ resource "aws_ec2_client_vpn_endpoint" "mobile" {
    + description = "Client VPN Endpoint for Mobile (Certificate)"
  }
```

### 4-3. リソース数の確認

**最後の行を確認**:
```
Plan: 43 to add, 0 to change, 0 to destroy.
```

**✅ 確認ポイント**:
- `43 to add` - 43個のリソースが作成される
- `0 to change` - 既存リソースの変更なし
- `0 to destroy` - 削除されるリソースなし

### 4-4. エラーチェック

**エラーがある場合の例**:
```
Error: Error reading file ../metadata/vpn-client-metadata.xml: no such file or directory
```

**解決方法**: ステップ1に戻ってSAMLメタデータをダウンロード

---

## 📝 パート5: デプロイ実行

### 5-1. デプロイ開始

```bash
# デプロイを実行
terraform apply
```

### 5-2. 確認プロンプト

**表示される内容**:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

**入力**:
```
yes
```

**⚠️ 重要**: `yes` と正確に入力してください。`y` や `Yes` では実行されません。

### 5-3. デプロイ進行状況の確認

**デプロイ中の表示例**:
```
aws_identitystore_group.vpn_users: Creating...
aws_identitystore_group.vpn_users: Creation complete after 2s [id=d-9067dc092d/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx]

aws_identitystore_group_membership.vpn_user_membership["b448d448-4061-7023-29b0-8901d5628601"]: Creating...
aws_identitystore_group_membership.vpn_user_membership["b448d448-4061-7023-29b0-8901d5628601"]: Creation complete after 1s

aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 3s [id=vpc-xxxxxxxxxxxxxxxxx]

aws_subnet.public[0]: Creating...
aws_subnet.public[1]: Creating...
aws_subnet.private[0]: Creating...
aws_subnet.private[1]: Creating...

...（続く）...

aws_ec2_client_vpn_endpoint.pc: Creating...
aws_ec2_client_vpn_endpoint.pc: Still creating... [10s elapsed]
aws_ec2_client_vpn_endpoint.pc: Still creating... [20s elapsed]
aws_ec2_client_vpn_endpoint.pc: Creation complete after 25s

aws_ec2_client_vpn_endpoint.mobile: Creating...
aws_ec2_client_vpn_endpoint.mobile: Still creating... [10s elapsed]
aws_ec2_client_vpn_endpoint.mobile: Creation complete after 22s
```

**デプロイ時間**: 約10-15分

**⚠️ 重要**: デプロイ中はターミナルを閉じないでください！

### 5-4. デプロイ完了の確認

**完了時の表示**:
```
Apply complete! Resources: 43 added, 0 changed, 0 destroyed.

Outputs:

identity_store_id = "d-9067dc092d"
nat_gateway_eip = "xx.xx.xx.xx"
sso_instance_arn = "arn:aws:sso:::instance/ssoins-72233d29e4c9ef9b"
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"
vpn_mobile_dns_name = "cvpn-endpoint-xxxxx.prod.clientvpn.ap-northeast-1.amazonaws.com"
vpn_mobile_endpoint_id = "cvpn-endpoint-xxxxx"
vpn_pc_endpoint_id = "cvpn-endpoint-xxxxx"
vpn_pc_self_service_url = "https://self-service.clientvpn.amazonaws.com/endpoints/cvpn-endpoint-xxxxx"
vpn_users_group_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
vpn_users_group_name = "VPN-Users"
```

**✅ 確認ポイント**:
- `Apply complete! Resources: 43 added` が表示される
- エラーメッセージがない
- Outputs に値が表示される

---

## 📝 パート6: デプロイ結果の確認

### 6-1. 出力値の確認

```bash
# すべての出力値を表示
terraform output
```

### 6-2. 重要な出力値をメモ

以下の値をメモしてください（後で使用します）:

```bash
# VPN-UsersグループID
terraform output vpn_users_group_id

# Self-Service Portal URL
terraform output vpn_pc_self_service_url

# 静的IP（Elastic IP）
terraform output nat_gateway_eip
```

### 6-3. グループ作成の確認

```bash
# AWS CLIでグループを確認
aws identitystore list-groups \
  --identity-store-id d-9067dc092d \
  --filters AttributePath=DisplayName,AttributeValue=VPN-Users
```

**期待される出力**:
```json
{
    "Groups": [
        {
            "GroupId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
            "DisplayName": "VPN-Users",
            "Description": "AWS Client VPN Users - Managed by Terraform",
            "IdentityStoreId": "d-9067dc092d"
        }
    ]
}
```

### 6-4. グループメンバーシップの確認

```bash
# グループメンバーを確認
aws identitystore list-group-memberships \
  --identity-store-id d-9067dc092d \
  --group-id $(terraform output -raw vpn_users_group_id)
```

**期待される出力**:
```json
{
    "GroupMemberships": [
        {
            "MembershipId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
            "GroupId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
            "MemberId": {
                "UserId": "b448d448-4061-7023-29b0-8901d5628601"
            }
        }
    ]
}
```

**✅ 確認ポイント**:
- y-kalen（User ID: b448d448-4061-7023-29b0-8901d5628601）がVPN-Usersグループに所属している

### 6-5. AWS Management Consoleで確認（オプション）

```
1. AWS Management Console > VPC > Client VPN Endpoints

2. 2個のエンドポイントが作成されていることを確認:
   - client-vpn-pc-endpoint (SAML認証)
   - client-vpn-mobile-endpoint (証明書認証)

3. ステータスが "available" になっていることを確認
```

---

## ✅ 完了確認

### チェックリスト

```
パート1: AWS認証
☑ aws login 完了
☑ aws sts get-caller-identity で認証確認

パート2: ファイル確認
☑ 証明書ファイル6個存在確認
☑ SAMLメタデータ2個存在確認
☑ terraform.tfvars 設定確認

パート3: Terraform初期化
☑ terraform init 完了
☑ terraform validate 成功

パート4: 実行計画
☑ terraform plan 実行
☑ 43リソース作成予定を確認
☑ エラーなし

パート5: デプロイ実行
☑ terraform apply 実行
☑ "yes" 入力
☑ 43リソース作成完了
☑ エラーなし

パート6: 結果確認
☑ terraform output 確認
☑ VPN-Usersグループ作成確認
☑ y-kalenがグループに所属確認
☑ VPNエンドポイント2個作成確認
```

---

## 🔧 トラブルシューティング

### エラー1: AWS認証エラー

**エラーメッセージ**:
```
Error: error configuring Terraform AWS Provider: no valid credential sources
```

**解決方法**:
```bash
# AWS認証を再実行
aws login

# 認証確認
aws sts get-caller-identity
```

### エラー2: SAMLメタデータが見つからない

**エラーメッセージ**:
```
Error: Error reading file ../metadata/vpn-client-metadata.xml: no such file or directory
```

**解決方法**:
1. ステップ1に戻ってSAMLメタデータをダウンロード
2. `metadata/`ディレクトリに正しく配置されているか確認
```bash
ls -la ../metadata/
```

### エラー3: ユーザーIDが無効

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
nano terraform.tfvars
```

### エラー4: デプロイ中にセッションが切れた

**症状**:
```
Credentials were refreshed, but the refreshed credentials are still expired.
```

**解決方法**:
```bash
# AWS認証を再実行
aws login

# Terraformを再実行（既に作成されたリソースはスキップされます）
terraform apply
```

---

## 🎉 ステップ2完了！

Terraformデプロイが完了しました。VPNインフラストラクチャが作成されました！

次のステップ: [03-group-assignment.md](03-group-assignment.md)

---

**作成日**: 2025年1月26日  
**最終更新**: 2025年1月26日  
**バージョン**: 1.0.0
