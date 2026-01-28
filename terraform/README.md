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

## デプロイ手順

### 1. 初期化
```bash
terraform init
```

### 2. プラン確認
```bash
# AWS認証情報をエクスポートしてプラン実行
eval $(aws configure export-credentials --format env) && terraform plan
```

または、シンプルに：
```bash
terraform plan
```
※ `aws login`で認証済みの場合、Terraformは自動的に認証情報を使用します

### 3. 適用
```bash
terraform apply
```

## 設定ファイル

`terraform.tfvars`を編集して、以下の値を設定してください：

```hcl
vpn_user_ids = ["your-user-id"]
organization_name = "YourOrganization"
vpn_domain = "vpn.example.com"
```

## リソース削除

```bash
terraform destroy
```

## トラブルシューティング

### AWS認証エラー
```bash
# 再ログイン
aws login

# 認証情報をエクスポート
eval $(aws configure export-credentials --format env)
```

## 詳細ドキュメント

詳細な手順については、`../docs/`ディレクトリのドキュメントを参照してください。
