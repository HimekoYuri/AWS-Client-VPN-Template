# AWS Client VPN ステップバイステップ手順書

## 📋 このフォルダについて

このフォルダには、AWS Client VPNをゼロからデプロイするための詳細な手順書が含まれています。

初めてデプロイする方は、**00-overview.md**から順番に読み進めてください。

---

## 📚 手順書一覧

### 🚀 基本デプロイ手順（推奨順序）

| ステップ | ファイル名 | 内容 | 所要時間 |
|---------|-----------|------|---------|
| **概要** | [00-overview.md](00-overview.md) | デプロイフロー全体の概要 | 5分 |
| **ステップ1** | [01-saml-application-setup.md](01-saml-application-setup.md) | SAML Application作成手順 | 15分 |
| **ステップ2** | [02-terraform-deployment.md](02-terraform-deployment.md) | Terraformデプロイ手順 | 10-15分 |
| **ステップ3** | [03-group-assignment.md](03-group-assignment.md) | グループ割り当て手順 | 5分 |
| **ステップ4** | [04-vpn-connection-test.md](04-vpn-connection-test.md) | VPN接続テスト手順 | 10分 |

**合計所要時間**: 約40-45分

---

### 📖 補足資料

| ファイル名 | 内容 | 用途 |
|-----------|------|------|
| [troubleshooting.md](troubleshooting.md) | トラブルシューティングガイド | 問題発生時の対処法 |
| [quick-reference.md](quick-reference.md) | クイックリファレンス | よく使うコマンド集 |

---

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

---

## 📝 前提条件

### ✅ 完了済み

- IAM Identity Center有効化済み
  - Identity Store ID: `d-9067dc092d`
  - SSO Instance: `ssoins-72233d29e4c9ef9b`
  
- ユーザー作成済み
  - User ID: `b448d448-4061-7023-29b0-8901d5628601`
  - Username: `y-kalen`
  
- 証明書生成済み
  - `certs/` ディレクトリに配置済み

- terraform.tfvars設定済み
  - `vpn_user_ids` 設定済み

### 🔧 必要な準備

- [ ] AWS Management Consoleへのアクセス
- [ ] AWS CLIの認証（`aws login`）
- [ ] Terraformのインストール（v1.0以上）

---

## 🚀 開始方法

### 初めてデプロイする場合

```
1. 00-overview.md を読んで全体像を把握

2. 01-saml-application-setup.md から順番に実施

3. 各ステップの完了チェックリストを確認

4. 問題が発生した場合は troubleshooting.md を参照
```

### 既にデプロイ済みの場合

```
- 新しいユーザーを追加: quick-reference.md の「新しいユーザーをVPNに追加」を参照

- VPN接続の問題: troubleshooting.md の該当セクションを参照

- よく使うコマンド: quick-reference.md を参照
```

---

## 📂 ファイル構成

```
step-by-step/
├── README.md                          # このファイル
├── 00-overview.md                     # 概要
├── 01-saml-application-setup.md       # SAML Application作成
├── 02-terraform-deployment.md         # Terraformデプロイ
├── 03-group-assignment.md             # グループ割り当て
├── 04-vpn-connection-test.md          # VPN接続テスト
├── troubleshooting.md                 # トラブルシューティング
└── quick-reference.md                 # クイックリファレンス
```

---

## 🎓 各ドキュメントの詳細

### 00-overview.md - 概要

**内容**:
- デプロイフロー全体の説明
- 所要時間の目安
- 前提条件の確認
- 手順書の使い方

**こんな時に読む**:
- 初めてデプロイする前
- 全体像を把握したい時

---

### 01-saml-application-setup.md - SAML Application作成

**内容**:
- VPN Client Application作成手順
- VPN Self-Service Application作成手順
- SAMLメタデータのダウンロード
- Attribute Mappingsの設定

**こんな時に読む**:
- SAML Applicationを作成する時
- SAMLメタデータを再ダウンロードする時

**重要なポイント**:
- Application ACS URLを正確にコピー
- Attribute Mappingsは5個必須
- memberOf属性を忘れずに設定

---

### 02-terraform-deployment.md - Terraformデプロイ

**内容**:
- AWS認証手順
- 証明書とメタデータの確認
- Terraform初期化
- 実行計画の確認
- デプロイ実行
- デプロイ結果の確認

**こんな時に読む**:
- Terraformでインフラをデプロイする時
- デプロイエラーが発生した時

**重要なポイント**:
- AWS認証を忘れずに
- terraform planで事前確認
- 43リソースが作成される

---

### 03-group-assignment.md - グループ割り当て

**内容**:
- VPN Client ApplicationへのグループAssign
- VPN Self-Service ApplicationへのグループAssign
- 割り当て確認

**こんな時に読む**:
- SAML ApplicationにグループをAssignする時
- ユーザーがVPNにアクセスできない時

**重要なポイント**:
- 両方のアプリケーションにAssign必須
- VPN-Usersグループを使用

---

### 04-vpn-connection-test.md - VPN接続テスト

**内容**:
- Self-Service Portalから設定ファイルをダウンロード
- AWS VPN Clientのインストール
- VPN接続設定
- VPN接続テスト
- 接続後の疎通確認
- CloudWatch Logsでログ確認

**こんな時に読む**:
- 初めてVPN接続する時
- VPN接続の問題をトラブルシューティングする時

**重要なポイント**:
- SAML認証が必要
- Split-Tunnel設定により、VPCへのトラフィックのみVPN経由

---

### troubleshooting.md - トラブルシューティング

**内容**:
- SAML Application作成時の問題
- Terraformデプロイ時の問題
- グループ割り当て時の問題
- VPN接続時の問題
- ネットワーク接続の問題
- 認証の問題
- ログとモニタリング

**こんな時に読む**:
- エラーが発生した時
- 問題の原因を特定したい時
- 解決方法を探している時

**重要なポイント**:
- エラーメッセージで検索
- CloudWatch Logsを確認
- よくある質問（FAQ）も参照

---

### quick-reference.md - クイックリファレンス

**内容**:
- よく使うコマンド集
- よく使う手順
- ログとモニタリング
- 重要な出力値
- セキュリティ
- ネットワーク
- 定期メンテナンス

**こんな時に読む**:
- コマンドを忘れた時
- 運用中に参照する時
- 定期メンテナンスを実施する時

**重要なポイント**:
- コマンドをコピペで使える
- ワンライナー集が便利
- ベストプラクティスも記載

---

## 🔍 よくある質問（FAQ）

### Q1: どのドキュメントから読めばいいですか？

**A**: 初めての場合は**00-overview.md**から順番に読んでください。

```
00-overview.md
  ↓
01-saml-application-setup.md
  ↓
02-terraform-deployment.md
  ↓
03-group-assignment.md
  ↓
04-vpn-connection-test.md
```

### Q2: エラーが発生しました。どうすればいいですか？

**A**: **troubleshooting.md**を参照してください。

```
1. troubleshooting.md でエラーメッセージを検索

2. 該当するセクションの解決方法を試す

3. それでも解決しない場合:
   - CloudWatch Logsを確認
   - ../troubleshooting.md（メインドキュメント）を確認
   - 社内のインフラチームに連絡
```

### Q3: よく使うコマンドを知りたいです

**A**: **quick-reference.md**を参照してください。

```
- AWS認証
- Terraform基本操作
- IAM Identity Center操作
- VPNエンドポイント操作
- ログとモニタリング
```

### Q4: 新しいユーザーを追加したいです

**A**: **quick-reference.md**の「新しいユーザーをVPNに追加」を参照してください。

```
方法1: Terraformで追加（推奨）
方法2: AWS Management Consoleで追加
```

### Q5: VPN接続できません

**A**: **troubleshooting.md**の「VPN接続時の問題」を参照してください。

```
よくある原因:
- グループ割り当てが完了していない
- SAML認証が失敗している
- 設定ファイルが正しくない
```

---

## 📞 サポート

### 問題が解決しない場合

```
1. troubleshooting.md を確認

2. ../troubleshooting.md（メインドキュメント）を確認

3. CloudWatch Logsでエラーログを確認
   AWS Management Console > CloudWatch > Log groups
   > /aws/clientvpn/pc-endpoint

4. 社内のインフラチームに連絡
   infra-team@example.com

5. AWSサポートに連絡（必要な場合）
   AWS Management Console > Support > Create case
```

### 必要な情報

AWSサポートに連絡する場合、以下の情報を準備してください:

```
1. VPNエンドポイントID
   terraform output vpn_pc_endpoint_id

2. エラーメッセージ（CloudWatch Logsから）

3. 発生日時

4. 再現手順

5. Terraformのバージョン
   terraform version

6. AWS CLIのバージョン
   aws --version
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
- ../terraform/SECURITY_CHECKLIST.md - セキュリティチェックリスト
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

### デプロイ前

```
✅ 00-overview.md を読んで全体像を把握
✅ 前提条件をすべて満たしているか確認
✅ AWS認証が有効か確認
✅ 証明書とSAMLメタデータが準備できているか確認
```

### デプロイ中

```
✅ 各ステップの完了チェックリストを確認
✅ エラーが発生したらすぐに troubleshooting.md を参照
✅ terraform plan で事前確認
✅ CloudWatch Logsでログを確認
```

### デプロイ後

```
✅ VPN接続テストを実施
✅ CloudWatch Logsでエラーがないか確認
✅ quick-reference.md をブックマーク
✅ 定期メンテナンスのスケジュールを設定
```

---

## 📊 デプロイ進捗チェックリスト

```
全体の進捗:
☐ 00-overview.md を読んだ
☐ 前提条件を確認した
☐ AWS認証を完了した

ステップ1: SAML Application作成
☐ VPN Client Application作成完了
☐ VPN Self-Service Application作成完了
☐ SAMLメタデータ2個ダウンロード完了
☐ metadata/フォルダに保存完了

ステップ2: Terraformデプロイ
☐ terraform init 完了
☐ terraform validate 成功
☐ terraform plan 確認
☐ terraform apply 完了（43リソース作成）
☐ terraform output 確認

ステップ3: グループ割り当て
☐ VPN Client ApplicationにVPN-UsersをAssign
☐ VPN Self-Service ApplicationにVPN-UsersをAssign
☐ 割り当て確認完了

ステップ4: VPN接続テスト
☐ Self-Service Portalにアクセス成功
☐ VPN設定ファイルダウンロード完了
☐ AWS VPN Clientインストール完了
☐ VPN接続成功
☐ 疎通確認完了
☐ CloudWatch Logsでログ確認

最終確認:
☐ すべてのステップが完了
☐ エラーログがない
☐ VPN接続が正常に動作
☐ quick-reference.md をブックマーク
```

---

## 🎉 デプロイ完了後

デプロイが完了したら、以下を実施してください:

```
1. VPN接続テストを実施
   04-vpn-connection-test.md を参照

2. quick-reference.md をブックマーク
   運用中に頻繁に参照します

3. 定期メンテナンスのスケジュールを設定
   - 証明書の更新（年1回）
   - ログのアーカイブ（月1回）
   - セキュリティ監査（四半期ごと）

4. チームメンバーにドキュメントを共有
   - このREADME.md
   - quick-reference.md
   - troubleshooting.md
```

---

**作成日**: 2025年1月26日  
**最終更新**: 2025年1月26日  
**バージョン**: 1.0.0

**次のステップ**: [00-overview.md](00-overview.md) から開始してください！
