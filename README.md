# AWS Client VPN Infrastructure

AWS Client VPNを使用したセキュアなリモートアクセス環境の構築プロジェクトです。

## 📑 目次

- [概要](#概要)
- [構成](#構成)
- [前提条件](#前提条件)
- [クイックスタート](#クイックスタート)
- [詳細ドキュメント](#詳細ドキュメント)
- [ディレクトリ構造](#ディレクトリ構造)
- [コスト見積もり](#コスト見積もり)
- [サポート・トラブルシューティング](#サポートトラブルシューティング)
- [参考資料](#参考資料)
- [セキュリティ](#セキュリティ)
- [ライセンス](#ライセンス)

---

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

## 🚀 クイックスタート

VPN環境を構築するには、以下のドキュメントを**番号順**に実行してください：

### ステップ1: 証明書の準備
📄 **[docs/01-easy-rsa-setup.md](docs/01-easy-rsa-setup.md)**

証明書生成ツール（easy-rsa）をセットアップし、VPN接続に必要な証明書を生成します。

```bash
# 自動スクリプトで証明書を生成（推奨）
./scripts/generate-certs.sh
```

### ステップ2: IAM Identity Centerの設定
📄 **[docs/02-iam-identity-center-setup.md](docs/02-iam-identity-center-setup.md)**

SAML認証のためのIAM Identity Centerを設定し、VPN用のグループとユーザーを作成します。

- VPN-Usersグループの作成
- SAMLアプリケーションの作成
- メタデータファイルのダウンロード

### ステップ3: Terraformデプロイ
📄 **[docs/03-deployment-guide.md](docs/03-deployment-guide.md)**

Terraformを使用してAWS Client VPNインフラストラクチャをデプロイします。

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### ステップ4: VPN接続テスト
📄 **PC用**: [docs/04-vpn-connection-pc.md](docs/04-vpn-connection-pc.md)  
📄 **モバイル用**: [docs/04-vpn-connection-mobile.md](docs/04-vpn-connection-mobile.md)

VPN接続をテストして、正常に動作することを確認します。

### ステップ5: 運用・メンテナンス
📄 **[docs/05-security-maintenance.md](docs/05-security-maintenance.md)**  
📄 **[docs/06-troubleshooting.md](docs/06-troubleshooting.md)**

定期的なメンテナンスとトラブルシューティングの方法を確認します。

---

## 📖 詳細ドキュメント

すべてのドキュメントは **[docs/](docs/)** ディレクトリに格納されています。

詳細は **[docs/README.md](docs/README.md)** を参照してください。

## 📂 ディレクトリ構造

```
.
├── README.md                           # このファイル（プロジェクト概要）
│
├── docs/                               # 📚 ドキュメント（番号順に実行）
│   ├── README.md                       # ドキュメント一覧
│   ├── 01-easy-rsa-setup.md           # ステップ1: 証明書の準備
│   ├── 02-iam-identity-center-setup.md # ステップ2: IAM Identity Center設定
│   ├── 02-saml-application-setup.md   # ステップ2: SAMLアプリケーション設定
│   ├── 03-deployment-guide.md         # ステップ3: Terraformデプロイ
│   ├── 03-deployment-checklist.md     # ステップ3: デプロイチェックリスト
│   ├── 04-vpn-connection-pc.md        # ステップ4: PC用VPN接続
│   ├── 04-vpn-connection-mobile.md    # ステップ4: モバイル用VPN接続
│   ├── 05-security-maintenance.md     # ステップ5: セキュリティメンテナンス
│   ├── 06-troubleshooting.md          # ステップ6: トラブルシューティング
│   ├── step-by-step/                  # 詳細ガイド
│   └── ...                            # その他の参考ドキュメント
│
├── terraform/                          # 🏗️ Terraformインフラストラクチャコード
│   ├── main.tf                        # プロバイダー設定
│   ├── vpc.tf                         # VPC設定
│   ├── subnets.tf                     # サブネット設定
│   ├── gateways.tf                    # ゲートウェイ設定
│   ├── route_tables.tf                # ルートテーブル設定
│   ├── security_groups.tf             # セキュリティグループ設定
│   ├── acm.tf                         # ACM証明書設定
│   ├── client_vpn_pc.tf               # PC用VPNエンドポイント（SAML認証）
│   ├── client_vpn_mobile.tf           # モバイル用VPNエンドポイント（証明書認証）
│   ├── iam_identity_center.tf         # IAM Identity Center設定
│   ├── iam_saml.tf                    # SAML認証設定
│   ├── cloudwatch.tf                  # CloudWatch Logs設定
│   ├── cloudtrail.tf                  # CloudTrail設定
│   ├── variables.tf                   # 変数定義
│   ├── outputs.tf                     # 出力定義
│   ├── versions.tf                    # Terraformバージョン設定
│   ├── terraform.tfvars.example       # 変数値のサンプル
│   └── terraform.tfvars               # 変数値（Git管理外）
│
├── certs/                              # 🔐 証明書ファイル（Git管理外）
│   ├── README.md                      # 証明書の説明
│   ├── ca.crt                         # CA証明書
│   ├── ca.key                         # CA秘密鍵（機密）
│   ├── server.crt                     # サーバー証明書
│   ├── server.key                     # サーバー秘密鍵（機密）
│   ├── client1.vpn.example.com.crt    # クライアント証明書
│   └── client1.vpn.example.com.key    # クライアント秘密鍵（機密）
│
├── easy-rsa/                           # 🔧 証明書生成ツール
│   └── easyrsa3/                      # easy-rsa v3
│       ├── easyrsa                    # 証明書生成スクリプト
│       └── pki/                       # PKIディレクトリ
│
├── metadata/                           # 📄 SAMLメタデータ（Git管理外）
│   ├── README.md                      # メタデータの説明
│   ├── vpn-client-metadata.xml        # VPN Clientメタデータ
│   └── vpn-self-service-metadata.xml  # Self-Serviceメタデータ
│
├── vpn-configs/                        # 📱 VPN設定ファイル（Git管理外）
│   ├── README.md                      # 設定ファイルの説明
│   └── mobile-vpn-config.ovpn         # モバイル用VPN設定
│
├── scripts/                            # 🛠️ 自動化スクリプト
│   ├── generate-certs.sh              # 証明書生成スクリプト（Linux/macOS）
│   ├── generate-certs.ps1             # 証明書生成スクリプト（Windows）
│   ├── check-aws-session.sh           # AWS認証確認スクリプト
│   └── check-aws-session.ps1          # AWS認証確認スクリプト（Windows）
│
├── tests/                              # 🧪 テストコード
│   ├── integration/                   # 統合テスト
│   ├── property/                      # プロパティベーステスト
│   └── requirements.txt               # Pythonテスト依存関係
│
└── .gitignore                          # Git除外設定
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

## 📞 サポート・トラブルシューティング

問題が発生した場合は、以下のドキュメントを参照してください：

1. **[docs/06-troubleshooting.md](docs/06-troubleshooting.md)** - トラブルシューティングガイド
2. **[docs/step-by-step/troubleshooting.md](docs/step-by-step/troubleshooting.md)** - 詳細トラブルシューティング
3. CloudWatch Logsでエラーログを確認
4. 社内のインフラチームに連絡

### よくある問題

- **VPN接続できない**: 証明書の有効期限、セキュリティグループの設定を確認
- **インターネットに接続できない**: NATゲートウェイの状態、ルートテーブルの設定を確認
- **認証エラー**: IAM Identity Centerの設定、SAMLメタデータを確認

詳細は [docs/06-troubleshooting.md](docs/06-troubleshooting.md) を参照してください。

## 📚 参考資料

### 公式ドキュメント
- [AWS Client VPN Administrator Guide](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/)
- [AWS IAM Identity Center User Guide](https://docs.aws.amazon.com/singlesignon/latest/userguide/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### 関連記事
- [AWS Client VPN TCP 443ポート移行ガイド](https://qiita.com/yuri_snowwhite/items/36a6e5014c89c05b7f7c)
  - TCP 443ポートへの移行手順と設定方法について詳しく解説されています

### プロジェクト内ドキュメント
- **[docs/README.md](docs/README.md)** - ドキュメント一覧
- **[certs/README.md](certs/README.md)** - 証明書の説明
- **[metadata/README.md](metadata/README.md)** - SAMLメタデータの説明
- **[vpn-configs/README.md](vpn-configs/README.md)** - VPN設定ファイルの説明
- **[scripts/README.md](scripts/README.md)** - スクリプトの説明
- **[tests/README.md](tests/README.md)** - テストの説明

## 🔒 セキュリティ

このプロジェクトでは、以下のセキュリティ対策を実装しています：

### 実装済みセキュリティ機能
- ✅ 証明書による相互TLS認証（モバイル用VPN）
- ✅ SAML 2.0認証 + MFA（PC用VPN）
- ✅ CloudTrailによる監査ログ記録
- ✅ CloudWatch Logsによる接続ログ記録
- ✅ S3バケットの暗号化とバージョニング
- ✅ セキュリティグループによるアクセス制御
- ✅ プライベートサブネットへのVPNエンドポイント配置
- ✅ NATゲートウェイによる送信元IP固定化

### セキュリティ推奨事項
- 証明書の定期的な更新（有効期限: 2028年4月）
- VPN接続ログの定期的な確認
- IAM Identity Centerユーザーの定期的なレビュー
- 不要な証明書の無効化
- MFAの必須化

詳細は **[docs/05-security-maintenance.md](docs/05-security-maintenance.md)** を参照してください。

## ライセンス

MIT License

## 作成者

構築日: 2026年1月26日
リージョン: ap-northeast-1 (東京)
