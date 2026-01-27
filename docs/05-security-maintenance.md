# セキュリティメンテナンスガイド

このドキュメントでは、AWS Client VPNインフラストラクチャのセキュリティメンテナンス手順を説明します。定期的なパッチ適用、証明書更新、セキュリティスキャンなどを実施して、システムのセキュリティを維持します。

## 📋 目次

- [定期メンテナンススケジュール](#定期メンテナンススケジュール)
- [証明書の更新](#証明書の更新)
- [Terraformのアップデート](#terraformのアップデート)
- [AWSリソースのパッチ適用](#awsリソースのパッチ適用)
- [セキュリティスキャン](#セキュリティスキャン)
- [ログの監視とレビュー](#ログの監視とレビュー)
- [インシデント対応](#インシデント対応)

## 定期メンテナンススケジュール

### 月次メンテナンス

- ✅ **証明書の有効期限確認**（毎月1日）
- ✅ **CloudWatch Logsのレビュー**（毎月1日）
- ✅ **セキュリティグループの監査**（毎月15日）
- ✅ **IAM Identity Centerユーザーの棚卸し**（毎月15日）

### 四半期メンテナンス

- ✅ **Terraformバージョンのアップデート**（四半期初月1日）
- ✅ **AWSプロバイダーのアップデート**（四半期初月1日）
- ✅ **セキュリティスキャンの実施**（四半期初月15日）
- ✅ **ドキュメントのレビューと更新**（四半期初月15日）

### 年次メンテナンス

- ✅ **証明書の更新**（証明書有効期限の3ヶ月前）
- ✅ **アーキテクチャレビュー**（年1回）
- ✅ **災害復旧テスト**（年1回）

## 証明書の更新

### 証明書の有効期限確認

#### ステップ1: 証明書の有効期限を確認

```bash
# サーバー証明書の有効期限を確認
openssl x509 -in certs/server.crt -noout -dates

# クライアント証明書の有効期限を確認
openssl x509 -in certs/client1.vpn.example.com.crt -noout -dates

# CA証明書の有効期限を確認
openssl x509 -in certs/ca.crt -noout -dates
```

**出力例**:
```
notBefore=Jan  1 00:00:00 2024 GMT
notAfter=Dec 31 23:59:59 2033 GMT
```

⚠️ **注意**: 有効期限の**3ヶ月前**に更新作業を開始してください。

### 証明書の更新手順

#### ステップ2: 新しい証明書を生成

```bash
# Windows PowerShell
.\scripts\generate-certs.ps1

# Bash
./scripts/generate-certs.sh
```

⚠️ **重要**: 既存の証明書ファイルはバックアップしてください。

```bash
# バックアップディレクトリを作成
mkdir -p certs/backup/$(date +%Y%m%d)

# 既存の証明書をバックアップ
cp certs/*.crt certs/backup/$(date +%Y%m%d)/
cp certs/*.key certs/backup/$(date +%Y%m%d)/
```

#### ステップ3: ACMに新しい証明書をインポート

```bash
cd terraform

# サーバー証明書を更新
terraform apply -replace=aws_acm_certificate.vpn_server

# クライアント証明書を更新
terraform apply -replace=aws_acm_certificate.vpn_client
```

#### ステップ4: VPNエンドポイントに新しい証明書を適用

```bash
# VPNエンドポイントを更新
terraform apply
```

⚠️ **ダウンタイム**: VPNエンドポイントの更新中（約5-10分）は、VPN接続が一時的に切断されます。メンテナンスウィンドウ（深夜・休日）に実施してください。

#### ステップ5: クライアント証明書の配布

新しいクライアント証明書をユーザーに配布します。

1. **配布方法を選択**:
   - セキュアなファイル共有サービス（Box、OneDrive）
   - 暗号化されたメール
   - 社内ポータル

2. **ユーザーに通知**:
   ```
   件名: 【重要】VPN証明書の更新について
   
   VPNユーザーの皆様
   
   VPN証明書の有効期限が近づいているため、新しい証明書を発行しました。
   以下の手順で証明書を更新してください。
   
   更新期限: YYYY年MM月DD日
   
   【PC用VPN】
   - 新しい設定ファイルをSelf-Service Portalからダウンロード
   - AWS VPN Clientで設定を更新
   
   【スマホ用VPN】
   - 新しいクライアント証明書をダウンロード
   - AWS VPN Clientで証明書をインポート
   
   詳細は以下のドキュメントを参照してください：
   - PC用: docs/vpn-connection-pc.md
   - スマホ用: docs/vpn-connection-mobile.md
   
   インフラチーム
   ```

#### ステップ6: 古い証明書の失効

すべてのユーザーが新しい証明書に移行したことを確認後、古い証明書を失効します。

```bash
# 古い証明書をACMから削除
aws acm delete-certificate \
  --certificate-arn <OLD_CERTIFICATE_ARN> \
  --region ap-northeast-1
```

## Terraformのアップデート

### Terraformバージョンのアップデート

#### ステップ1: 現在のバージョンを確認

```bash
terraform version
```

#### ステップ2: 最新バージョンを確認

https://www.terraform.io/downloads にアクセスして、最新の安定版を確認します。

#### ステップ3: Terraformをアップデート

**Windows**:
```powershell
# Chocolateyを使用
choco upgrade terraform

# または手動でダウンロード
# https://www.terraform.io/downloads からダウンロードして解凍
```

**macOS**:
```bash
# Homebrewを使用
brew upgrade terraform
```

**Linux**:
```bash
# 最新版をダウンロード
wget https://releases.hashicorp.com/terraform/1.x.x/terraform_1.x.x_linux_amd64.zip
unzip terraform_1.x.x_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

#### ステップ4: バージョン制約を更新

`terraform/versions.tf`を更新します：

```hcl
terraform {
  required_version = ">= 1.x.x"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

#### ステップ5: 動作確認

```bash
cd terraform

# 初期化
terraform init -upgrade

# 検証
terraform validate

# 実行計画を確認
terraform plan
```

### AWSプロバイダーのアップデート

#### ステップ1: 最新バージョンを確認

https://registry.terraform.io/providers/hashicorp/aws/latest にアクセスして、最新バージョンを確認します。

#### ステップ2: バージョン制約を更新

`terraform/versions.tf`を更新します：

```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.x"  # 最新のメジャーバージョン
  }
}
```

#### ステップ3: プロバイダーをアップデート

```bash
cd terraform

# プロバイダーをアップデート
terraform init -upgrade

# 変更を確認
terraform plan
```

⚠️ **注意**: メジャーバージョンアップの場合は、破壊的変更がある可能性があります。必ず[変更ログ](https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md)を確認してください。

## AWSリソースのパッチ適用

### VPNエンドポイントの更新

AWS Client VPNエンドポイントは、AWSによって自動的にパッチが適用されます。ただし、設定の見直しは定期的に実施してください。

#### セキュリティ設定の確認

```bash
# VPNエンドポイントの設定を確認
aws ec2 describe-client-vpn-endpoints \
  --region ap-northeast-1 \
  --query 'ClientVpnEndpoints[*].[ClientVpnEndpointId,TransportProtocol,VpnPort,Status.Code]' \
  --output table
```

**確認項目**:
- ✅ TransportProtocol: `udp`
- ✅ VpnPort: `443`
- ✅ Status: `available`

### セキュリティグループの監査

#### ステップ1: セキュリティグループのルールを確認

```bash
# セキュリティグループのルールを確認
aws ec2 describe-security-groups \
  --group-names client-vpn-endpoint-sg \
  --region ap-northeast-1 \
  --query 'SecurityGroups[0].IpPermissions' \
  --output json
```

#### ステップ2: 不要なルールを削除

不要なインバウンドルールがある場合は、Terraformコードを修正して削除します。

```hcl
# terraform/security_groups.tf
resource "aws_security_group" "vpn_endpoint" {
  # 必要最小限のルールのみ定義
  ingress {
    description = "VPN client traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

```bash
# 変更を適用
terraform apply
```

## セキュリティスキャン

### Terraformコードのセキュリティスキャン

#### ステップ1: プロパティベーステストを実行

```bash
# プロパティベーステストを実行
cd tests
pytest property/ -v --hypothesis-show-statistics
```

**確認項目**:
- ✅ 機密情報が平文で含まれていないこと
- ✅ AWS認証情報が平文で保存されていないこと

#### ステップ2: tfsecでスキャン

```bash
# tfsecをインストール（初回のみ）
# Windows
choco install tfsec

# macOS
brew install tfsec

# Linux
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# スキャンを実行
cd terraform
tfsec .
```

#### ステップ3: Checkovでスキャン

```bash
# Checkovをインストール（初回のみ）
pip install checkov

# スキャンを実行
cd terraform
checkov -d .
```

### AWSリソースのセキュリティスキャン

#### AWS Security Hubの有効化

```bash
# Security Hubを有効化
aws securityhub enable-security-hub --region ap-northeast-1

# CIS AWS Foundations Benchmarkを有効化
aws securityhub batch-enable-standards \
  --standards-subscription-requests StandardsArn=arn:aws:securityhub:ap-northeast-1::standards/cis-aws-foundations-benchmark/v/1.2.0 \
  --region ap-northeast-1
```

#### AWS Configの有効化

```bash
# AWS Configを有効化（Terraformで管理することを推奨）
# terraform/config.tf を作成して設定
```

### 脆弱性スキャン結果の記録

スキャン結果は`test-results/`ディレクトリに保存します：

```bash
# スキャン結果を保存
mkdir -p test-results
tfsec terraform/ > test-results/tfsec-scan-$(date +%Y%m%d).log
checkov -d terraform/ > test-results/checkov-scan-$(date +%Y%m%d).log
```

## ログの監視とレビュー

### CloudWatch Logsのレビュー

#### 月次レビュー

```bash
# 過去30日間の接続ログを確認
aws logs filter-log-events \
  --log-group-name /aws/clientvpn/pc \
  --start-time $(date -d '30 days ago' +%s)000 \
  --region ap-northeast-1 \
  --query 'events[*].[timestamp,message]' \
  --output table
```

**確認項目**:
- ✅ 認証失敗の回数（異常な増加がないか）
- ✅ 接続元IPアドレス（不審なIPからの接続がないか）
- ✅ 接続時間帯（営業時間外の接続が多くないか）

#### 異常検知

CloudWatch Logsのメトリクスフィルターを設定して、異常を自動検知します。

```bash
# 認証失敗のメトリクスフィルターを作成
aws logs put-metric-filter \
  --log-group-name /aws/clientvpn/pc \
  --filter-name AuthenticationFailures \
  --filter-pattern "[timestamp, request_id, event_type=authentication-failure, ...]" \
  --metric-transformations \
    metricName=AuthenticationFailures,metricNamespace=ClientVPN,metricValue=1 \
  --region ap-northeast-1
```

### CloudTrailのレビュー

```bash
# Client VPN関連のイベントを確認
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::EC2::ClientVpnEndpoint \
  --start-time $(date -d '30 days ago' +%s) \
  --region ap-northeast-1 \
  --query 'Events[*].[EventTime,EventName,Username]' \
  --output table
```

**確認項目**:
- ✅ VPNエンドポイントの変更履歴
- ✅ セキュリティグループの変更履歴
- ✅ IAM SAML Providerの変更履歴

## インシデント対応

### セキュリティインシデントの検知

以下の兆候がある場合は、セキュリティインシデントの可能性があります：

- ⚠️ 認証失敗の急増
- ⚠️ 不審なIPアドレスからの接続試行
- ⚠️ 営業時間外の大量接続
- ⚠️ 証明書の不正使用

### インシデント対応手順

#### ステップ1: インシデントの確認

```bash
# 最近の接続ログを確認
aws logs tail /aws/clientvpn/pc --follow --region ap-northeast-1

# 認証失敗を検索
aws logs filter-log-events \
  --log-group-name /aws/clientvpn/pc \
  --filter-pattern "authentication-failure" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --region ap-northeast-1
```

#### ステップ2: 影響範囲の特定

```bash
# 接続中のユーザーを確認
aws ec2 describe-client-vpn-connections \
  --client-vpn-endpoint-id <ENDPOINT_ID> \
  --region ap-northeast-1 \
  --query 'Connections[?Status.Code==`active`].[Username,ClientIp,ConnectionEstablishedTime]' \
  --output table
```

#### ステップ3: 緊急対応

**不審な接続を切断**:
```bash
# 特定の接続を切断
aws ec2 terminate-client-vpn-connections \
  --client-vpn-endpoint-id <ENDPOINT_ID> \
  --connection-id <CONNECTION_ID> \
  --region ap-northeast-1
```

**証明書を失効**:
```bash
# 不正使用された証明書を削除
aws acm delete-certificate \
  --certificate-arn <CERTIFICATE_ARN> \
  --region ap-northeast-1
```

**VPNエンドポイントを一時停止**（最終手段）:
```bash
# 認可ルールを削除して接続を拒否
aws ec2 revoke-client-vpn-ingress \
  --client-vpn-endpoint-id <ENDPOINT_ID> \
  --target-network-cidr 0.0.0.0/0 \
  --region ap-northeast-1
```

#### ステップ4: 根本原因の調査

1. **ログの詳細分析**
   - CloudWatch Logsで不審な活動を調査
   - CloudTrailでAPI呼び出しを調査

2. **影響を受けたユーザーの特定**
   - IAM Identity Centerでユーザーアカウントを確認
   - パスワードリセットを実施

3. **セキュリティ設定の見直し**
   - セキュリティグループのルールを確認
   - 認可ルールを確認

#### ステップ5: 再発防止策の実施

1. **MFAの強制**
   - すべてのユーザーにMFAを強制

2. **IPアドレス制限**
   - 必要に応じて、特定のIPアドレス範囲からのみ接続を許可

3. **監視の強化**
   - CloudWatch Alarmsで異常を自動検知

4. **ユーザー教育**
   - セキュリティ意識向上のトレーニングを実施

## セキュリティチェックリスト

### 月次チェックリスト

- [ ] 証明書の有効期限を確認
- [ ] CloudWatch Logsをレビュー
- [ ] 認証失敗の回数を確認
- [ ] 不審なIPアドレスからの接続を確認
- [ ] IAM Identity Centerユーザーの棚卸し
- [ ] セキュリティグループのルールを確認

### 四半期チェックリスト

- [ ] Terraformバージョンをアップデート
- [ ] AWSプロバイダーをアップデート
- [ ] セキュリティスキャンを実施（tfsec、Checkov）
- [ ] プロパティベーステストを実行
- [ ] ドキュメントをレビューして更新
- [ ] 災害復旧計画をレビュー

### 年次チェックリスト

- [ ] 証明書を更新
- [ ] アーキテクチャレビューを実施
- [ ] 災害復旧テストを実施
- [ ] セキュリティポリシーをレビュー
- [ ] コンプライアンス監査を実施

## サポート

セキュリティに関する質問や懸念事項がある場合は、以下に連絡してください：

- **セキュリティチーム**: security@example.com
- **インフラチーム**: infrastructure@example.com
- **緊急連絡先**: +81-XX-XXXX-XXXX（24時間対応）

---

**作成日**: 2024年
**最終更新**: 2024年
**バージョン**: 1.0.0
