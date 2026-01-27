# AWS Client VPN Infrastructure - デプロイ手順書

## 📋 概要

このドキュメントは、AWS Client VPN InfrastructureをTerraformでデプロイするための詳細な手順を記載しています。

**デプロイ時間**: 約10-15分  
**デプロイリージョン**: ap-northeast-1（東京）  
**作成されるリソース数**: 41個

---

## ⚠️ デプロイ前の確認事項

### 必須条件

- [ ] AWS認証が完了している（`aws login`実行済み）
- [ ] 証明書ファイルが`certs/`ディレクトリに配置されている
  - `ca.crt`
  - `ca.key`
  - `server.crt`
  - `server.key`
  - `client1.vpn.example.com.crt`
  - `client1.vpn.example.com.key`
- [ ] SAMLメタデータが`metadata/`ディレクトリに配置されている
  - `vpn-client-metadata.xml`
  - `vpn-self-service-metadata.xml`
- [ ] `terraform/terraform.tfvars`にIAM Identity CenterグループIDが設定されている

### 推奨事項

- [ ] AWS認証セッションを最長に設定（12時間）
- [ ] デプロイ中はターミナルを閉じない
- [ ] デプロイログを記録する

---

## 🚀 デプロイ手順

### ステップ1: AWS認証の設定

```bash
# ターミナルを開く
cd /mnt/d/CloudDrive/Google/Client-VPN-test/terraform

# AWS認証（方法1: aws login）
aws login

# または、AWS認証（方法2: 一時認証情報を環境変数に設定）
export AWS_ACCESS_KEY_ID="<YOUR_ACCESS_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<YOUR_SECRET_ACCESS_KEY>"
export AWS_SESSION_TOKEN="<YOUR_SESSION_TOKEN>"

# 認証確認
aws sts get-caller-identity
```

**期待される出力**:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX:y-kalen",
    "Account": "620360464874",
    "Arn": "arn:aws:sts::620360464874:assumed-role/AWSReservedSSO_AdministratorAccess_61485ef71d1c3c46/y-kalen"
}
```

---

### ステップ2: 必要なファイルの確認

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

**⚠️ 注意**: ファイルが存在しない場合は、以下を実行してください：
- 証明書: `../scripts/generate-certs.sh`を実行
- SAMLメタデータ: `docs/iam-identity-center-setup.md`の手順に従ってダウンロード

---

### ステップ3: Terraform変数の設定

```bash
# terraform.tfvarsファイルを編集
nano terraform.tfvars

# または、viエディタを使用
vi terraform.tfvars
```

**terraform.tfvarsの内容**:
```hcl
# IAM Identity Center Configuration
iic_vpn_group_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # 実際のグループIDに置き換え

# Organization Configuration
organization_name = "YourOrganization"  # 組織名に置き換え
vpn_domain        = "vpn.example.com"   # VPNドメイン名に置き換え
```

**IAM Identity CenterグループIDの取得方法**:
1. AWS Management Consoleを開く
2. IAM Identity Centerに移動
3. Groups → VPN用グループを選択
4. グループIDをコピー

---

### ステップ4: Terraform初期化

```bash
# Terraformディレクトリに移動（既に移動済みの場合はスキップ）
cd /mnt/d/CloudDrive/Google/Client-VPN-test/terraform

# Terraform初期化
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

**⚠️ エラーが発生した場合**:
- インターネット接続を確認
- プロキシ設定を確認
- `.terraform`ディレクトリを削除して再実行: `rm -rf .terraform && terraform init`

---

### ステップ5: 実行計画の確認

```bash
# 実行計画を表示
terraform plan

# または、実行計画をファイルに保存
terraform plan -out=tfplan
```

**確認ポイント**:
- 作成されるリソース数: **41個**
- 変更されるリソース: **0個**
- 削除されるリソース: **0個**

**主要なリソース**:
- VPC: 1個
- サブネット: 4個（パブリック2個、プライベート2個）
- NAT Gateway: 1個
- Elastic IP: 1個
- Client VPNエンドポイント: 2個（PC用、スマホ用）
- セキュリティグループ: 1個
- CloudWatch Logsグループ: 2個
- CloudTrail: 1個
- S3バケット: 1個
- ACM証明書: 2個
- IAM SAMLプロバイダー: 2個

**⚠️ エラーが発生した場合**:
- 証明書ファイルのパスを確認
- SAMLメタデータファイルのパスを確認
- terraform.tfvarsの設定を確認

---

### ステップ6: デプロイ実行

```bash
# デプロイ実行（確認プロンプトあり）
terraform apply

# または、事前に保存した実行計画を使用
terraform apply tfplan

# または、確認プロンプトをスキップ（非推奨）
terraform apply -auto-approve
```

**デプロイ中の表示**:
```
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 2s [id=vpc-xxxxxxxxxxxxxxxxx]
aws_subnet.public[0]: Creating...
aws_subnet.public[1]: Creating...
aws_subnet.private[0]: Creating...
aws_subnet.private[1]: Creating...
...
Apply complete! Resources: 41 added, 0 changed, 0 destroyed.
```

**デプロイ時間**: 約10-15分

**⚠️ 重要**: デプロイ中は以下に注意してください：
- ターミナルを閉じない
- AWS認証セッションが切れないようにする
- エラーが発生した場合は、ログを保存する

---

### ステップ7: デプロイ結果の確認

```bash
# 出力値を表示
terraform output

# 期待される出力:
# nat_gateway_eip = "xx.xx.xx.xx"  # 静的送信元IP
# vpc_id = "vpc-xxxxxxxxxxxxxxxxx"
# vpn_mobile_dns_name = "cvpn-endpoint-xxxxxxxxxxxxxxxxx.prod.clientvpn.ap-northeast-1.amazonaws.com"
# vpn_mobile_endpoint_id = "cvpn-endpoint-xxxxxxxxxxxxxxxxx"
# vpn_pc_endpoint_id = "cvpn-endpoint-xxxxxxxxxxxxxxxxx"
# vpn_pc_self_service_url = "https://self-service.clientvpn.amazonaws.com/endpoints/cvpn-endpoint-xxxxxxxxxxxxxxxxx"
```

**確認項目**:
- [ ] VPCが作成されている
- [ ] NAT GatewayにElastic IPが割り当てられている
- [ ] PC用VPNエンドポイントが作成されている
- [ ] スマホ用VPNエンドポイントが作成されている
- [ ] Self-Service Portal URLが表示されている

---

### ステップ8: AWS Management Consoleでの確認

#### VPCの確認
1. AWS Management Console → VPC
2. VPCが作成されていることを確認（192.168.0.0/16）
3. サブネットが4個作成されていることを確認

#### Client VPNエンドポイントの確認
1. AWS Management Console → VPC → Client VPN Endpoints
2. 2個のエンドポイントが作成されていることを確認
   - PC用: SAML認証
   - スマホ用: 証明書認証
3. ステータスが「available」になっていることを確認

#### CloudWatch Logsの確認
1. AWS Management Console → CloudWatch → Log groups
2. 以下のロググループが作成されていることを確認
   - `/aws/clientvpn/pc`
   - `/aws/clientvpn/mobile`

#### CloudTrailの確認
1. AWS Management Console → CloudTrail → Trails
2. トレイルが作成されていることを確認
3. ログ記録が有効になっていることを確認

---

## 📊 デプロイ後の作業

### 1. VPN接続テスト（PC用）

```bash
# Self-Service Portal URLにアクセス
# terraform outputで表示されたURLをブラウザで開く
```

1. IAM Identity Centerでログイン
2. MFA認証を完了
3. VPN設定ファイルをダウンロード
4. AWS VPN Clientに設定ファイルをインポート
5. VPN接続をテスト

**詳細手順**: `docs/vpn-connection-pc.md`を参照

### 2. VPN接続テスト（スマホ用）

1. クライアント証明書を配布
2. AWS VPN Clientをインストール
3. 証明書と設定ファイルをインポート
4. VPN接続をテスト

**詳細手順**: `docs/vpn-connection-mobile.md`を参照

### 3. 静的IPの確認

```bash
# VPN接続後、送信元IPを確認
curl https://api.ipify.org

# terraform outputで表示されたElastic IPと一致することを確認
```

### 4. 統合テストの実行

```bash
# プロジェクトルートに移動
cd /mnt/d/CloudDrive/Google/Client-VPN-test

# Python仮想環境をアクティブ化
source venv/bin/activate

# 統合テストを実行
pytest tests/integration/ -v

# テスト結果を保存
pytest tests/integration/ -v > test-results/integration-tests-post-deployment.log 2>&1
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

# または、環境変数を再設定
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"
```

---

### エラー2: 証明書ファイルが見つからない

**エラーメッセージ**:
```
Error: Error reading file: no such file or directory
```

**解決方法**:
```bash
# 証明書ファイルの存在を確認
ls -la ../certs/

# 証明書が存在しない場合は生成
cd ..
./scripts/generate-certs.sh
cd terraform
```

---

### エラー3: SAMLメタデータが見つからない

**エラーメッセージ**:
```
Error: Error reading file ../metadata/vpn-client-metadata.xml: no such file or directory
```

**解決方法**:
1. IAM Identity Centerでメタデータをダウンロード
2. `metadata/`ディレクトリに配置
3. ファイル名を確認: `vpn-client-metadata.xml`, `vpn-self-service-metadata.xml`

**詳細手順**: `docs/iam-identity-center-setup.md`を参照

---

### エラー4: リソース作成エラー

**エラーメッセージ**:
```
Error: Error creating EC2 Client VPN Endpoint: InvalidParameterValue
```

**解決方法**:
1. terraform.tfvarsの設定を確認
2. IAM Identity CenterグループIDが正しいか確認
3. SAMLメタデータが最新であるか確認
4. エラーログを確認: `terraform apply 2>&1 | tee deploy-error.log`

---

### エラー5: デプロイ中にセッションが切れた

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

## 🗑️ リソースの削除

**⚠️ 警告**: この操作は全てのリソースを削除します。本番環境では慎重に実行してください。

```bash
# リソースの削除
terraform destroy

# 確認プロンプトで "yes" を入力

# または、確認プロンプトをスキップ（非推奨）
terraform destroy -auto-approve
```

**削除時間**: 約5-10分

---

## 📝 デプロイログの保存

```bash
# デプロイログを保存
terraform apply 2>&1 | tee ../test-results/terraform-apply-$(date +%Y%m%d-%H%M%S).log

# デプロイ結果を保存
terraform output > ../test-results/terraform-output-$(date +%Y%m%d-%H%M%S).txt
```

---

## 📞 サポート

問題が発生した場合は、以下を確認してください：

1. [トラブルシューティングガイド](troubleshooting.md)
2. [セキュリティメンテナンス](security-maintenance.md)
3. CloudWatch Logsでエラーログを確認
4. 社内のインフラチームに連絡

---

## ✅ デプロイチェックリスト

### デプロイ前
- [ ] AWS認証完了
- [ ] 証明書ファイル配置完了
- [ ] SAMLメタデータ配置完了
- [ ] terraform.tfvars設定完了
- [ ] terraform init実行完了
- [ ] terraform plan確認完了

### デプロイ中
- [ ] terraform apply実行中
- [ ] エラーなく進行中
- [ ] ターミナルを閉じていない

### デプロイ後
- [ ] terraform output確認完了
- [ ] AWS Management Consoleで確認完了
- [ ] VPN接続テスト完了（PC用）
- [ ] VPN接続テスト完了（スマホ用）
- [ ] 静的IP確認完了
- [ ] 統合テスト実行完了
- [ ] デプロイログ保存完了

---

**作成日**: 2025年1月25日  
**最終更新**: 2025年1月25日  
**バージョン**: 1.0.0
