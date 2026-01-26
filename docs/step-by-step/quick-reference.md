# クイックリファレンス

## 📋 このドキュメントについて

AWS Client VPNの運用で頻繁に使用するコマンドと手順をまとめたクイックリファレンスです。

---

## 🚀 よく使うコマンド

### AWS認証

```bash
# AWS SSOでログイン
aws login

# 認証確認
aws sts get-caller-identity

# 期待される出力:
# Account: 620360464874
# Arn: arn:aws:sts::620360464874:assumed-role/.../y-kalen
```

### Terraform基本操作

```bash
# プロジェクトディレクトリに移動
cd /mnt/d/CloudDrive/Google/Client-VPN-test/terraform

# 初期化
terraform init

# 構文チェック
terraform validate

# 実行計画の確認
terraform plan

# デプロイ
terraform apply

# 出力値の確認
terraform output

# 特定の出力値を表示
terraform output vpn_users_group_id
terraform output vpn_pc_self_service_url

# リソースの削除
terraform destroy
```

### IAM Identity Center操作

```bash
# ユーザー一覧
aws identitystore list-users \
  --identity-store-id d-9067dc092d

# グループ一覧
aws identitystore list-groups \
  --identity-store-id d-9067dc092d

# 特定のグループを検索
aws identitystore list-groups \
  --identity-store-id d-9067dc092d \
  --filters AttributePath=DisplayName,AttributeValue=VPN-Users

# グループメンバー一覧
aws identitystore list-group-memberships \
  --identity-store-id d-9067dc092d \
  --group-id <GROUP_ID>
```

### VPNエンドポイント操作

```bash
# VPNエンドポイント一覧
aws ec2 describe-client-vpn-endpoints \
  --region ap-northeast-1

# 特定のVPNエンドポイントの詳細
aws ec2 describe-client-vpn-endpoints \
  --client-vpn-endpoint-ids cvpn-endpoint-xxxxx \
  --region ap-northeast-1

# VPNエンドポイントの接続状況
aws ec2 describe-client-vpn-connections \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --region ap-northeast-1
```

---

## 📝 よく使う手順

### 新しいユーザーをVPNに追加

#### 方法1: Terraformで追加（推奨）

```bash
# 1. ユーザーIDを取得
aws identitystore list-users \
  --identity-store-id d-9067dc092d

# 2. terraform.tfvarsを編集
cd /mnt/d/CloudDrive/Google/Client-VPN-test/terraform
nano terraform.tfvars

# 3. vpn_user_idsに追加
vpn_user_ids = [
  "b448d448-4061-7023-29b0-8901d5628601",  # y-kalen
  "new-user-id-here"                       # 新しいユーザー
]

# 4. 適用
terraform apply

# 5. 確認
terraform output vpn_users_group_id
aws identitystore list-group-memberships \
  --identity-store-id d-9067dc092d \
  --group-id $(terraform output -raw vpn_users_group_id)
```

#### 方法2: AWS Management Consoleで追加

```
1. AWS Management Console > IAM Identity Center

2. Groups > VPN-Users

3. 「Add users to group」をクリック

4. ユーザーを選択

5. 「Add users」をクリック
```

**⚠️ 注意**: 方法2で追加した場合、Terraformの管理外になります。

### VPN接続設定ファイルの再ダウンロード

```
1. ブラウザでSelf-Service Portal URLを開く
   https://self-service.clientvpn.amazonaws.com/endpoints/cvpn-endpoint-xxxxx

2. IAM Identity Centerでログイン

3. 「Download Client Configuration」をクリック

4. downloaded-client-config.ovpn を保存
```

### VPN接続のトラブルシューティング

```
1. VPN接続を切断

2. AWS VPN Clientを再起動

3. プロファイルを削除して再追加
   File > Manage Profiles > Remove > Add Profile

4. 設定ファイルを再ダウンロード

5. 再接続
```

---

## 🔍 ログとモニタリング

### CloudWatch Logsの確認

```bash
# ロググループ一覧
aws logs describe-log-groups \
  --log-group-name-prefix /aws/clientvpn \
  --region ap-northeast-1

# 最新のログストリーム
aws logs describe-log-streams \
  --log-group-name /aws/clientvpn/pc-endpoint \
  --order-by LastEventTime \
  --descending \
  --max-items 5 \
  --region ap-northeast-1

# ログイベントの取得
aws logs get-log-events \
  --log-group-name /aws/clientvpn/pc-endpoint \
  --log-stream-name <LOG_STREAM_NAME> \
  --limit 50 \
  --region ap-northeast-1
```

### AWS Management Consoleでログ確認

```
1. AWS Management Console > CloudWatch > Log groups

2. /aws/clientvpn/pc-endpoint をクリック

3. 最新のログストリームをクリック

4. エラーを検索:
   - Filter: "ERROR"
   - Filter: "FAILED"
   - Filter: "DENIED"
```

---

## 📊 重要な出力値

### Terraform出力値

```bash
cd /mnt/d/CloudDrive/Google/Client-VPN-test/terraform

# すべての出力値
terraform output

# 個別の出力値
terraform output identity_store_id          # d-9067dc092d
terraform output sso_instance_arn           # arn:aws:sso:::instance/ssoins-72233d29e4c9ef9b
terraform output vpn_users_group_id         # グループID
terraform output vpn_users_group_name       # VPN-Users
terraform output vpn_pc_endpoint_id         # cvpn-endpoint-xxxxx
terraform output vpn_pc_self_service_url    # Self-Service Portal URL
terraform output vpn_mobile_endpoint_id     # cvpn-endpoint-xxxxx
terraform output vpn_mobile_dns_name        # DNS名
terraform output vpc_id                     # vpc-xxxxx
terraform output nat_gateway_eip            # 静的IP
```

### 環境情報

```
AWS Account ID: 620360464874
Region: ap-northeast-1
Identity Store ID: d-9067dc092d
SSO Instance: ssoins-72233d29e4c9ef9b
VPC CIDR: 192.168.0.0/16
```

---

## 🔐 セキュリティ

### 証明書の確認

```bash
# 証明書ファイルの確認
ls -la /mnt/d/CloudDrive/Google/Client-VPN-test/certs/

# 証明書の有効期限確認
openssl x509 -in certs/server.crt -noout -dates
openssl x509 -in certs/ca.crt -noout -dates

# 証明書の詳細確認
openssl x509 -in certs/server.crt -noout -text
```

### セキュリティグループの確認

```bash
# セキュリティグループ一覧
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=*vpn*" \
  --region ap-northeast-1

# 特定のセキュリティグループの詳細
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx \
  --region ap-northeast-1
```

---

## 🌐 ネットワーク

### VPC情報の確認

```bash
# VPC一覧
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=*client-vpn*" \
  --region ap-northeast-1

# サブネット一覧
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=*client-vpn*" \
  --region ap-northeast-1

# ルートテーブル一覧
aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=*client-vpn*" \
  --region ap-northeast-1

# NATゲートウェイ一覧
aws ec2 describe-nat-gateways \
  --filter "Name=tag:Name,Values=*client-vpn*" \
  --region ap-northeast-1
```

### 接続テスト

```bash
# VPN接続後のIPアドレス確認
# Windows
ipconfig | findstr "AWS VPN"

# Linux/macOS
ifconfig | grep -A 5 tun

# VPC内のリソースへのping
ping 192.168.2.10

# インターネット接続確認
curl -I https://www.google.com

# DNSの確認
nslookup google.com
```

---

## 📱 モバイルVPN（証明書認証）

### 証明書のエクスポート

```bash
# クライアント証明書の確認
ls -la certs/client1.vpn.example.com.*

# PKCS12形式に変換（iOS/Android用）
openssl pkcs12 -export \
  -in certs/client1.vpn.example.com.crt \
  -inkey certs/client1.vpn.example.com.key \
  -certfile certs/ca.crt \
  -out certs/client1.p12 \
  -passout pass:YourPassword

# 変換されたファイルを確認
ls -la certs/client1.p12
```

### モバイルVPN設定ファイルのダウンロード

```bash
# モバイルVPNエンドポイントのDNS名を取得
cd /mnt/d/CloudDrive/Google/Client-VPN-test/terraform
terraform output vpn_mobile_dns_name

# 出力例:
# cvpn-endpoint-xxxxx.prod.clientvpn.ap-northeast-1.amazonaws.com
```

詳細は `../vpn-connection-mobile.md` を参照

---

## 🔄 定期メンテナンス

### 証明書の更新（年1回）

```bash
# 証明書の有効期限確認
openssl x509 -in certs/server.crt -noout -dates

# 有効期限が近い場合、証明書を再生成
cd /mnt/d/CloudDrive/Google/Client-VPN-test
./scripts/generate-certs.sh

# Terraformで更新
cd terraform
terraform apply
```

### ログのアーカイブ（月1回）

```
1. AWS Management Console > CloudWatch > Log groups

2. /aws/clientvpn/pc-endpoint

3. Actions > Export data to Amazon S3

4. S3バケットを選択

5. 日付範囲を指定

6. Export
```

### セキュリティ監査（四半期ごと）

```bash
# CloudTrailでVPN関連のイベントを確認
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::EC2::ClientVpnEndpoint \
  --max-results 50 \
  --region ap-northeast-1

# 不正なアクセス試行を確認
aws logs filter-log-events \
  --log-group-name /aws/clientvpn/pc-endpoint \
  --filter-pattern "DENIED" \
  --region ap-northeast-1
```

---

## 📞 緊急時の連絡先

### 社内サポート

```
インフラチーム: infra-team@example.com
セキュリティチーム: security-team@example.com
```

### AWSサポート

```
AWSサポートケース作成:
AWS Management Console > Support > Create case

必要な情報:
- VPNエンドポイントID
- エラーメッセージ
- 発生日時
- CloudWatch Logsのスクリーンショット
```

---

## 🔗 関連ドキュメント

### プロジェクト内ドキュメント

```
基本ドキュメント:
- ../README.md - プロジェクト概要
- ../deployment-guide.md - デプロイガイド
- ../troubleshooting.md - トラブルシューティング

IAM Identity Center:
- ../iam-identity-center-setup.md - IIC初期設定
- ../iam-identity-center-terraform-guide.md - IIC Terraform化
- ../existing-iic-setup.md - 既存IIC利用

VPN接続:
- ../vpn-connection-pc.md - PC用VPN接続手順
- ../vpn-connection-mobile.md - モバイル用VPN接続手順

セキュリティ:
- ../security-maintenance.md - セキュリティメンテナンス
- terraform/SECURITY_CHECKLIST.md - セキュリティチェックリスト

ステップバイステップ手順:
- 00-overview.md - 概要
- 01-saml-application-setup.md - SAML Application作成
- 02-terraform-deployment.md - Terraformデプロイ
- 03-group-assignment.md - グループ割り当て
- 04-vpn-connection-test.md - VPN接続テスト
- troubleshooting.md - トラブルシューティング
- quick-reference.md - このドキュメント
```

### AWS公式ドキュメント

```
AWS Client VPN:
https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/

IAM Identity Center:
https://docs.aws.amazon.com/singlesignon/latest/userguide/

Terraform AWS Provider:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs
```

---

## 💡 ベストプラクティス

### セキュリティ

```
✅ 定期的に証明書を更新（年1回）
✅ CloudWatch Logsを定期的に確認（週1回）
✅ 不要なユーザーをグループから削除
✅ MFAを必須化
✅ セキュリティグループのルールを最小限に
```

### 運用

```
✅ Terraformでインフラを管理
✅ terraform.tfvarsをバージョン管理から除外
✅ 証明書と秘密鍵を安全に保管
✅ 定期的にバックアップ
✅ 変更前にterraform planで確認
```

### コスト最適化

```
✅ 不要なVPNエンドポイントを削除
✅ CloudWatch Logsの保持期間を適切に設定
✅ NATゲートウェイの使用状況を監視
✅ Elastic IPの未使用を確認
```

---

## 📊 コマンドチートシート

### ワンライナー集

```bash
# VPN接続中のユーザー数を確認
aws ec2 describe-client-vpn-connections \
  --client-vpn-endpoint-id $(cd terraform && terraform output -raw vpn_pc_endpoint_id) \
  --region ap-northeast-1 \
  --query 'Connections[?Status.Code==`active`]' \
  --output json | jq length

# 今日のVPN接続ログを確認
aws logs filter-log-events \
  --log-group-name /aws/clientvpn/pc-endpoint \
  --start-time $(date -d 'today 00:00:00' +%s)000 \
  --region ap-northeast-1

# VPN-Usersグループのメンバー数を確認
aws identitystore list-group-memberships \
  --identity-store-id d-9067dc092d \
  --group-id $(cd terraform && terraform output -raw vpn_users_group_id) \
  --query 'GroupMemberships' \
  --output json | jq length

# VPCのリソース数を確認
aws ec2 describe-vpcs \
  --vpc-ids $(cd terraform && terraform output -raw vpc_id) \
  --region ap-northeast-1 \
  --query 'Vpcs[0]' \
  --output json

# NATゲートウェイの料金を概算
# 1時間あたり: $0.062
# 1GBあたり: $0.062
echo "NATゲートウェイ月額概算: $((0.062 * 24 * 30)) USD (データ転送費別)"
```

---

**作成日**: 2025年1月26日  
**最終更新**: 2025年1月26日  
**バージョン**: 1.0.0

**次のステップ**: 実際の運用を開始してください！
