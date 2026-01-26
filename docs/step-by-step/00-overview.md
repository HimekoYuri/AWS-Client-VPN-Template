# AWS Client VPN デプロイ手順書 - 概要

## 📋 このフォルダについて

このフォルダには、AWS Client VPNをゼロからデプロイするための詳細な手順書が含まれています。

## 📚 手順書一覧

### 基本デプロイ手順（推奨順序）

1. **00-overview.md** - この概要ファイル
2. **01-saml-application-setup.md** - SAML Application作成手順
3. **02-terraform-deployment.md** - Terraformデプロイ手順
4. **03-group-assignment.md** - グループ割り当て手順
5. **04-vpn-connection-test.md** - VPN接続テスト手順

### 補足資料

- **troubleshooting.md** - トラブルシューティングガイド
- **quick-reference.md** - クイックリファレンス

## 🎯 デプロイフロー

```
【手動作業】
ステップ1: SAML Application作成（2個）
   ↓
ステップ2: SAMLメタデータダウンロード（2個）
   ↓
【Terraform自動化】
ステップ3: Terraformデプロイ（43リソース作成）
   ↓
【手動作業】
ステップ4: SAML ApplicationにグループAssign
   ↓
ステップ5: VPN接続テスト
```

## ⏱️ 所要時間

- **SAML Application作成**: 約15分
- **Terraformデプロイ**: 約10-15分
- **グループ割り当て**: 約5分
- **VPN接続テスト**: 約10分

**合計**: 約40-45分

## 📝 前提条件

### 完了済み

- ✅ IAM Identity Center有効化済み
  - Identity Store ID: `d-9067dc092d`
  - SSO Instance: `ssoins-72233d29e4c9ef9b`
  
- ✅ ユーザー作成済み
  - User ID: `b448d448-4061-7023-29b0-8901d5628601`
  - Username: `y-kalen`
  
- ✅ 証明書生成済み
  - `certs/` ディレクトリに配置済み

- ✅ terraform.tfvars設定済み
  - `vpn_user_ids` 設定済み

### 必要な準備

- [ ] AWS Management Consoleへのアクセス
- [ ] AWS CLIの認証（`aws login`）
- [ ] Terraformのインストール（v1.0以上）

## 🚀 開始方法

1. **ステップ1から順番に実施**してください
2. 各ステップの完了チェックリストを確認
3. 問題が発生した場合は`troubleshooting.md`を参照

## 📞 サポート

問題が発生した場合:
1. `troubleshooting.md`を確認
2. `../troubleshooting.md`（メインドキュメント）を確認
3. CloudWatch Logsでエラーログを確認
4. 社内のインフラチームに連絡

---

**作成日**: 2025年1月26日  
**最終更新**: 2025年1月26日  
**バージョン**: 1.0.0

次のステップ: [01-saml-application-setup.md](01-saml-application-setup.md)
