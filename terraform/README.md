# AWS Client VPN Terraform Configuration

このディレクトリには、AWS Client VPNインフラストラクチャをデプロイするためのTerraform設定が含まれています。

## 前提条件

1. **AWS認証情報**
   ```bash
   aws login
   ```

2. **必要なファイル**
   - 証明書ファイル: `../certs/`
   - SAMLメタデータ: `../metadata/`
   - 設定ファイル: `terraform.tfvars`

3. **IAM Identity Center**
   - IAM Identity Centerが有効化されていること
   - SAML Applicationが作成されていること

## デプロイ手順（モジュール毎）

### 重要: モジュール毎のデプロイが推奨されます
全リソースを一度にデプロイすると、VPNエンドポイントのネットワーク関連付けで30分以上かかり、AWS認証がタイムアウトする可能性があります。

### 0. 初期化
```bash
terraform init
```

### 1. VPC・ネットワーク基盤
```bash
eval "$(aws configure export-credentials --profile default --format env)" && \
terraform apply \
  -target=aws_vpc.main \
  -target=aws_subnet.public \
  -target=aws_subnet.private \
  -target=aws_internet_gateway.main \
  -target=aws_eip.nat \
  -target=aws_nat_gateway.main \
  -target=aws_route_table.public \
  -target=aws_route_table.private \
  -target=aws_route_table_association.public \
  -target=aws_route_table_association.private \
  -auto-approve
```

### 2. セキュリティグループ・CloudWatch・証明書
```bash
eval "$(aws configure export-credentials --profile default --format env)" && \
terraform apply \
  -target=aws_security_group.vpn_endpoint \
  -target=aws_cloudwatch_log_group.vpn_mobile \
  -target=aws_cloudwatch_log_group.vpn_pc \
  -target=aws_cloudwatch_log_stream.vpn_mobile \
  -target=aws_cloudwatch_log_stream.vpn_pc \
  -target=aws_acm_certificate.vpn_server \
  -target=aws_acm_certificate.vpn_client \
  -auto-approve
```

### 3. IAM Identity Center・CloudTrail・S3
```bash
eval "$(aws configure export-credentials --profile default --format env)" && \
terraform apply \
  -target=aws_identitystore_group.vpn_users \
  -target=aws_s3_bucket.cloudtrail \
  -target=aws_s3_bucket_versioning.cloudtrail \
  -target=aws_s3_bucket_public_access_block.cloudtrail \
  -target=aws_s3_bucket_server_side_encryption_configuration.cloudtrail \
  -target=aws_s3_bucket_policy.cloudtrail \
  -target=aws_cloudtrail.main \
  -target=aws_iam_saml_provider.vpn_client \
  -auto-approve
```

### 4. Mobile VPNエンドポイント（証明書認証）
```bash
eval "$(aws configure export-credentials --profile default --format env)" && \
terraform apply \
  -target=aws_ec2_client_vpn_endpoint.mobile \
  -auto-approve
```

### 5. PC VPNエンドポイント（SAML認証）
```bash
eval "$(aws configure export-credentials --profile default --format env)" && \
terraform apply \
  -target=aws_ec2_client_vpn_endpoint.pc \
  -auto-approve
```

### 6. 残りのリソース（ネットワーク関連付け・ルート・認可ルール）
```bash
eval "$(aws configure export-credentials --profile default --format env)" && \
terraform apply -auto-approve
```

認証がタイムアウトした場合は、再度`aws login`を実行してから、同じコマンドを再実行してください。

## 削除手順（モジュール毎）

### 重要: 削除もモジュール毎に実行してください

### 1. VPNルート・認可ルールを削除
```bash
eval "$(aws configure export-credentials --profile default --format env)" && \
terraform destroy \
  -target=aws_ec2_client_vpn_route.mobile_internet \
  -target=aws_ec2_client_vpn_route.pc_internet \
  -target=aws_ec2_client_vpn_authorization_rule.mobile_internet \
  -target=aws_ec2_client_vpn_authorization_rule.pc_vpn_users \
  -auto-approve
```

### 2. VPNネットワーク関連付けを削除
```bash
eval "$(aws configure export-credentials --profile default --format env)" && \
terraform destroy \
  -target=aws_ec2_client_vpn_network_association.mobile \
  -target=aws_ec2_client_vpn_network_association.pc \
  -auto-approve
```

### 3. VPNエンドポイントを削除
```bash
eval "$(aws configure export-credentials --profile default --format env)" && \
terraform destroy \
  -target=aws_ec2_client_vpn_endpoint.mobile \
  -target=aws_ec2_client_vpn_endpoint.pc \
  -auto-approve
```

### 4. 残りのリソースを削除
```bash
eval "$(aws configure export-credentials --profile default --format env)" && \
terraform destroy -auto-approve
```

## 設定ファイル

`terraform.tfvars`を編集して、以下の値を設定してください：

```hcl
vpn_user_ids = ["your-user-id"]
```

## トラブルシューティング

### 認証タイムアウト
長時間のデプロイ中に認証が切れた場合：
```bash
aws login
eval "$(aws configure export-credentials --profile default --format env)"
terraform apply -auto-approve  # 中断したステップから再実行
```

### VPNネットワーク関連付けのタイムアウト
30分以上待っても完了しない場合、リソースは実際には作成されている可能性があります：
```bash
# 状態を更新
terraform apply -refresh-only -auto-approve
# 再度apply
terraform apply -auto-approve
```

## 構成ファイル

- `main.tf` - プロバイダー設定
- `vpc.tf` - VPC設定
- `subnets.tf` - サブネット設定
- `gateways.tf` - Internet Gateway / NAT Gateway
- `route_tables.tf` - ルートテーブル
- `security_groups.tf` - セキュリティグループ
- `acm.tf` - ACM証明書
- `cloudwatch.tf` - CloudWatch Logs
- `cloudtrail.tf` - CloudTrail監査ログ
- `iam_identity_center.tf` - IAM Identity Center
- `client_vpn_mobile.tf` - Mobile VPNエンドポイント（証明書認証）
- `client_vpn_pc.tf` - PC VPNエンドポイント（SAML認証）
- `outputs.tf` - 出力値
- `variables.tf` - 変数定義
