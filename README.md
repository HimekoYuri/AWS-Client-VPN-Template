# AWS Client VPN Infrastructure

AWS Client VPNを使用したセキュアなリモートアクセス環境の構築プロジェクトです。

## 概要

このプロジェクトは、Terraformを使用してAWS Client VPNインフラストラクチャを構築します。
PC向けのSAML認証とモバイルデバイス向けの証明書認証、2つのVPN接続環境を提供します。

## 構成

### ネットワーク
- VPC: 192.168.0.0/16
- パブリックサブネット: 2個 (ap-northeast-1a, 1c)
- プライベートサブネット: 2個 (ap-northeast-1a, 1c)
- NATゲートウェイ: インターネットアクセス用
- インターネットゲートウェイ

### VPNエンドポイント

#### PC用VPN (SAML認証)
- **プロトコル**: TCP 443
- **認証方式**: IAM Identity Center (SAML 2.0)
- **クライアントCIDR**: 172.16.0.0/22
- **Split Tunnel**: 無効 (全トラフィックVPN経由)
- **認可**: 全認証済みユーザー許可

#### モバイル用VPN (証明書認証)
- **プロトコル**: TCP 443
- **認証方式**: 相互TLS証明書認証
- **クライアントCIDR**: 172.17.0.0/22
- **Split Tunnel**: 無効 (全トラフィックVPN経由)
- **認可**: 全認証済みユーザー許可

### セキュリティ
- CloudTrail: 監査ログ記録
- CloudWatch Logs: VPN接続ログ
- S3バケット暗号化: SSE-S3
- セキュリティグループ: TCP 443のみ許可

### 認証・認可
- IAM Identity Center統合 (PC用VPN)
- 証明書ベース認証 (モバイル用VPN)
- 全認証済みユーザーにインターネットアクセス許可

## 前提条件

- Terraform >= 1.0
- AWS CLI v2
- OpenSSL
- IAM Identity Centerが有効化されていること
- SAML 2.0アプリケーション設定済み (PC用VPN)

## セットアップ

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd Client-VPN-test
```

### 2. 証明書の生成

```bash
cd easy-rsa/easyrsa3

# CA証明書の初期化
./easyrsa init-pki
./easyrsa build-ca nopass

# サーバー証明書の生成
./easyrsa build-server-full server.vpn.example.com nopass

# クライアント証明書の生成
./easyrsa build-client-full client1.vpn.example.com nopass

# 証明書をcertsディレクトリにコピー
cd ../..
mkdir -p certs
cp easy-rsa/easyrsa3/pki/ca.crt certs/
cp easy-rsa/easyrsa3/pki/issued/server.vpn.example.com.crt certs/
cp easy-rsa/easyrsa3/pki/private/server.vpn.example.com.key certs/
cp easy-rsa/easyrsa3/pki/issued/client1.vpn.example.com.crt certs/
cp easy-rsa/easyrsa3/pki/private/client1.vpn.example.com.key certs/
```

### 3. IAM Identity Centerの設定

```bash
# VPN-Usersグループの作成
aws identitystore create-group \
  --identity-store-id <your-identity-store-id> \
  --display-name "VPN-Users" \
  --description "VPN接続が許可されたユーザーグループ"

# ユーザーの作成とグループへの追加
aws identitystore create-user \
  --identity-store-id <your-identity-store-id> \
  --user-name "vpn-test" \
  --display-name "vpn-test" \
  --name GivenName=VPN,FamilyName=Test \
  --emails Value=vpn-test@example.com,Type=work,Primary=true
```

### 4. Terraformでインフラ構築

```bash
cd terraform

# 初期化
terraform init

# 変数ファイルの編集
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvarsを編集してユーザーIDなどを設定

# プラン確認
terraform plan

# 適用
terraform apply
```

### 5. VPN設定ファイルの生成

```bash
# モバイル用VPN設定ファイルのエクスポート
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id <endpoint-id> \
  --region ap-northeast-1 \
  --output text > mobile-vpn-config.ovpn

# 証明書を設定ファイルに追加
cat >> mobile-vpn-config.ovpn << EOF

<cert>
$(cat certs/client1.vpn.example.com.crt)
</cert>

<key>
$(cat certs/client1.vpn.example.com.key)
</key>
EOF
```

## 使用方法

### モバイルVPN接続

1. OpenVPN Connectアプリをインストール
2. `mobile-vpn-config.ovpn`をインポート
3. 接続ボタンをタップ
4. 証明書で自動認証され、接続完了

## ディレクトリ構造

```
.
├── README.md                   # このファイル
├── terraform/                  # Terraformコード
│   ├── main.tf                # プロバイダー設定
│   ├── vpc.tf                 # VPC設定
│   ├── subnets.tf             # サブネット設定
│   ├── gateways.tf            # ゲートウェイ設定
│   ├── route_tables.tf        # ルートテーブル設定
│   ├── security_groups.tf     # セキュリティグループ設定
│   ├── acm.tf                 # ACM証明書設定
│   ├── client_vpn_mobile.tf   # モバイルVPNエンドポイント
│   ├── iam_identity_center.tf # IAM Identity Center設定
│   ├── cloudwatch.tf          # CloudWatch Logs設定
│   ├── cloudtrail.tf          # CloudTrail設定
│   ├── variables.tf           # 変数定義
│   ├── outputs.tf             # 出力定義
│   └── terraform.tfvars       # 変数値（Git管理外）
├── certs/                      # 証明書ファイル（Git管理外）
├── easy-rsa/                   # 証明書生成ツール
├── metadata/                   # SAMLメタデータ（Git管理外）
├── docs/                       # ドキュメント
│   ├── DEPLOYMENT_GUIDE.md    # デプロイメントガイド
│   └── TROUBLESHOOTING.md     # トラブルシューティング
└── .gitignore                  # Git除外設定
```

## セキュリティ考慮事項

### 実装済み
- ✅ 証明書による相互TLS認証
- ✅ CloudTrailによる監査ログ記録
- ✅ CloudWatch Logsによる接続ログ記録
- ✅ S3バケットの暗号化とバージョニング
- ✅ セキュリティグループによるアクセス制御
- ✅ プライベートサブネットへのVPNエンドポイント配置
- ✅ NATゲートウェイによる送信元IP固定化

### 推奨事項
- 証明書の定期的な更新（有効期限: 2028年4月）
- VPN接続ログの定期的な確認
- IAM Identity Centerユーザーの定期的なレビュー
- 不要な証明書の無効化

## コスト見積もり

### 月額概算（東京リージョン）
- Client VPNエンドポイント: $73
- NAT Gateway: $45 + データ転送料
- CloudWatch Logs: 使用量による
- S3 (CloudTrail): 使用量による

**合計**: 約 $120-150/月

## トラブルシューティング

### VPN接続できない
- 証明書の有効期限を確認
- セキュリティグループの設定を確認
- CloudWatch Logsでエラーを確認

### インターネットに接続できない
- NATゲートウェイの状態を確認
- ルートテーブルの設定を確認
- split-tunnelが無効になっているか確認

詳細は [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) を参照してください。

## 参考資料

### 関連記事
- [AWS Client VPN TCP 443ポート移行ガイド](https://qiita.com/yuri_snowwhite/items/36a6e5014c89c05b7f7c)
  - TCP 443ポートへの移行手順と設定方法について詳しく解説されています

## ライセンス

MIT License

## 作成者

構築日: 2026年1月26日
リージョン: ap-northeast-1 (東京)
