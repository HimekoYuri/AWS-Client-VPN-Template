# AWS Client VPN ドキュメント

このディレクトリには、AWS Client VPNインフラストラクチャの構築・運用に関する各種ドキュメントが格納されています。

## 📚 ドキュメント一覧（実行順）

以下の順番でドキュメントを参照して、VPN環境を構築してください。

### ステップ1: 証明書の準備
- **[01-easy-rsa-setup.md](01-easy-rsa-setup.md)** - 証明書生成ツールのセットアップと証明書作成手順

### ステップ2: IAM Identity Centerの設定
- **[02-iam-identity-center-setup.md](02-iam-identity-center-setup.md)** - SAML認証のためのIAM Identity Center設定手順
- **[02-saml-application-setup.md](02-saml-application-setup.md)** - SAMLアプリケーションの詳細設定手順

### ステップ3: Terraformデプロイ
- **[03-deployment-guide.md](03-deployment-guide.md)** - Terraformを使用したインフラストラクチャのデプロイ手順
- **[03-deployment-checklist.md](03-deployment-checklist.md)** - デプロイ前後の確認チェックリスト

### ステップ4: VPN接続テスト
- **[04-vpn-connection-pc.md](04-vpn-connection-pc.md)** - PC用VPN（SAML認証）の接続手順
- **[04-vpn-connection-mobile.md](04-vpn-connection-mobile.md)** - モバイル用VPN（証明書認証）の接続手順

### ステップ5: 運用・メンテナンス
- **[05-security-maintenance.md](05-security-maintenance.md)** - セキュリティメンテナンスと証明書更新手順
- **[06-troubleshooting.md](06-troubleshooting.md)** - トラブルシューティングガイド

## 📖 参考ドキュメント

### 詳細ガイド
- **[step-by-step/](step-by-step/)** - より詳細なステップバイステップガイド
  - [00-overview.md](step-by-step/00-overview.md) - 全体概要
  - [01-saml-application-setup.md](step-by-step/01-saml-application-setup.md) - SAML設定詳細
  - [02-terraform-deployment.md](step-by-step/02-terraform-deployment.md) - Terraformデプロイ詳細
  - [03-group-assignment.md](step-by-step/03-group-assignment.md) - グループ割り当て
  - [04-vpn-connection-test.md](step-by-step/04-vpn-connection-test.md) - 接続テスト詳細
  - [quick-reference.md](step-by-step/quick-reference.md) - クイックリファレンス
  - [troubleshooting.md](step-by-step/troubleshooting.md) - 詳細トラブルシューティング

### その他の参考ドキュメント
- **[99-deployment-result.md](99-deployment-result.md)** - 構築済み環境の情報（実行結果）
- **[99-existing-iic-setup-reference.md](99-existing-iic-setup-reference.md)** - 既存のIAM Identity Center環境を使用する場合の手順
- **[99-iam-identity-center-terraform-guide.md](99-iam-identity-center-terraform-guide.md)** - TerraformでIAM Identity Centerを管理する方法
- **[99-pc-vpn-saml-setup-reference.md](99-pc-vpn-saml-setup-reference.md)** - PC用VPN SAML設定の参考資料

## 🚀 クイックスタート

初めての方は、以下の順序で進めてください：

1. **証明書の準備**: [01-easy-rsa-setup.md](01-easy-rsa-setup.md)を参照して証明書を生成
2. **IAM設定**: [02-iam-identity-center-setup.md](02-iam-identity-center-setup.md)を参照してSAML認証を設定
3. **デプロイ**: [03-deployment-guide.md](03-deployment-guide.md)を参照してTerraformでインフラを構築
4. **接続テスト**: [04-vpn-connection-pc.md](04-vpn-connection-pc.md)または[04-vpn-connection-mobile.md](04-vpn-connection-mobile.md)を参照してVPN接続をテスト

## ⚠️ 注意事項

- すべてのドキュメントは日本語で記述されています
- 機密情報（パスワード、秘密鍵、APIキー）は記載しないでください
- スクリーンショットを含める場合は、機密情報をマスキングしてください
- 本番環境での作業前に、必ずテスト環境で手順を確認してください

## 📞 サポート

問題が発生した場合は、まず[06-troubleshooting.md](06-troubleshooting.md)を参照してください。
解決しない場合は、社内のインフラチームにお問い合わせください。
