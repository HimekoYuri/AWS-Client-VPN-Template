# Terraformディレクトリ

このディレクトリには、AWS Client VPNインフラストラクチャを構築するためのTerraformコードを格納します。

## ディレクトリ構造

```
terraform/
├── main.tf              # プロバイダー設定
├── versions.tf          # Terraformとプロバイダーのバージョン制約
├── variables.tf         # 変数定義
├── outputs.tf           # 出力定義
├── vpc.tf              # VPCリソース
├── subnets.tf          # サブネットリソース
├── gateways.tf         # Internet Gateway、NAT Gateway
├── route_tables.tf     # ルートテーブル
├── security_groups.tf  # セキュリティグループ
├── acm.tf              # AWS Certificate Manager（証明書インポート）
├── iam_saml.tf         # IAM SAML Identity Provider
├── cloudwatch.tf       # CloudWatch Logs
├── client_vpn_pc.tf    # PC用Client VPNエンドポイント
├── client_vpn_mobile.tf # スマホ用Client VPNエンドポイント
└── cloudtrail.tf       # CloudTrail設定
```

## 使用方法

### 1. 初期化

```bash
cd terraform
terraform init
```

### 2. 変数ファイルの作成

`terraform.tfvars` ファイルを作成し、必要な変数を設定してください：

```hcl
aws_region = "ap-northeast-1"
iic_vpn_group_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
organization_name = "YourOrganization"
vpn_domain = "vpn.example.com"
```

**⚠️ 注意**: `terraform.tfvars` は `.gitignore` で除外されているため、Gitにコミットされません。

### 3. 実行計画の確認

```bash
terraform plan
```

### 4. インフラストラクチャのデプロイ

```bash
terraform apply
```

### 5. リソースの削除

```bash
terraform destroy
```

## 主要なリソース

### VPCとネットワーク
- **VPC**: 192.168.0.0/16
- **パブリックサブネット**: 192.168.1.0/24, 192.168.2.0/24
- **プライベートサブネット**: 192.168.10.0/24, 192.168.11.0/24
- **NAT Gateway**: Elastic IP付き（静的送信元IP）
- **Internet Gateway**: VPCにアタッチ
- **パブリックルートテーブル**: Internet Gateway経由でインターネットアクセス
- **プライベートルートテーブル**: NAT Gateway経由でインターネットアクセス（VPN用）

### Client VPNエンドポイント
- **PC用**: SAML + MFA認証、Client CIDR 172.16.0.0/22
- **スマホ用**: 証明書認証、Client CIDR 172.17.0.0/22

### セキュリティ
- **セキュリティグループ**: UDP 443のみ許可（Client VPNエンドポイント用）
  - インバウンド: UDP 443（VPNクライアント接続用）
  - アウトバウンド: 全トラフィック許可（インターネットアクセス用）
  - OWASP基準準拠: 最小権限の原則に基づく設定
- **CloudWatch Logs**: 接続ログを記録
- **CloudTrail**: API呼び出しを記録

## 変数

| 変数名 | 説明 | デフォルト値 | 必須 |
|--------|------|-------------|------|
| `aws_region` | AWSリージョン | `ap-northeast-1` | No |
| `vpc_cidr` | VPC CIDRブロック | `192.168.0.0/16` | No |
| `vpn_client_cidr_pc` | PC用VPN Client CIDR | `172.16.0.0/22` | No |
| `vpn_client_cidr_mobile` | スマホ用VPN Client CIDR | `172.17.0.0/22` | No |
| `iic_vpn_group_id` | IAM Identity Center グループID | - | **Yes** |
| `organization_name` | 組織名（証明書用） | `YourOrganization` | No |
| `vpn_domain` | VPNドメイン名 | `vpn.example.com` | No |

## 出力

| 出力名 | 説明 |
|--------|------|
| `vpc_id` | VPC ID |
| `nat_gateway_eip` | NAT Gateway Elastic IP（静的送信元IP） |
| `vpn_pc_endpoint_id` | PC用VPNエンドポイントID |
| `vpn_mobile_endpoint_id` | スマホ用VPNエンドポイントID |
| `vpn_pc_self_service_url` | PC用VPN Self-Service Portal URL |
| `vpn_mobile_dns_name` | スマホ用VPNエンドポイントDNS名 |

## セキュリティのベストプラクティス

### 機密情報の管理
- ✅ 変数ファイル（`*.tfvars`）はGitにコミットしない
- ✅ 証明書秘密鍵は `file()` 関数で読み込み、コードに埋め込まない
- ✅ SAMLメタデータは `file()` 関数で読み込み、コードに埋め込まない
- ✅ パスワードやAPIキーは平文で記載しない

### リソース保護
- ✅ 重要なリソースには `prevent_destroy = true` を設定
- ✅ リソース作成時は `create_before_destroy = true` を使用
- ✅ 依存関係は `depends_on` で明示的に定義

### アクセス制御
- ✅ セキュリティグループは最小権限の原則に従う
- ✅ IAMロールとポリシーは最小権限で設定
- ✅ VPNアクセスはグループベースで制御

## トラブルシューティング

### terraform init エラー

```
Error: Failed to download provider
```

**解決方法**: インターネット接続を確認し、プロキシ設定が正しいか確認してください。

### terraform plan エラー

```
Error: Error reading file: no such file or directory
```

**解決方法**: 証明書ファイルとSAMLメタデータファイルが正しい場所に配置されているか確認してください。

### AWS認証エラー

```
Error: error configuring Terraform AWS Provider: no valid credential sources
```

**解決方法**: `aws login` を実行してAWSに認証してください。

## 参考資料

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Client VPN Administrator Guide](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
