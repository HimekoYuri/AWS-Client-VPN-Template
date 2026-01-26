# トラブルシューティングガイド

## 📋 このドキュメントについて

AWS Client VPNデプロイ中に発生する可能性のある問題と解決方法をまとめています。

---

## 🔍 目次

1. [SAML Application作成時の問題](#1-saml-application作成時の問題)
2. [Terraformデプロイ時の問題](#2-terraformデプロイ時の問題)
3. [グループ割り当て時の問題](#3-グループ割り当て時の問題)
4. [VPN接続時の問題](#4-vpn接続時の問題)
5. [ネットワーク接続の問題](#5-ネットワーク接続の問題)
6. [認証の問題](#6-認証の問題)
7. [ログとモニタリング](#7-ログとモニタリング)

---

## 1. SAML Application作成時の問題

### 問題1-1: メタデータダウンロードリンクが表示されない

**症状**:
```
「IAM Identity Center SAML metadata file」のリンクが見つからない
```

**原因**:
- アプリケーションの設定が保存されていない
- ページが完全に読み込まれていない

**解決方法**:
```
1. アプリケーションの設定を再確認
2. 「Submit」をクリックして保存
3. ブラウザをリロード（F5キー）
4. 「Actions」> 「Edit attribute mappings」を再度開く
5. ページを下にスクロールしてメタデータセクションを探す
```

### 問題1-2: Attribute Mappingsの設定が保存されない

**症状**:
```
Attribute Mappingsを設定したが、再度開くと消えている
```

**原因**:
- 「Submit」ボタンをクリックしていない
- ブラウザのセッションが切れた

**解決方法**:
```
1. すべてのAttribute Mappingsを再入力
2. 必ず「Submit」ボタンをクリック
3. 成功メッセージを確認
4. アプリケーション一覧に戻って再度開いて確認
```

### 問題1-3: Application ACS URLの入力エラー

**症状**:
```
Error: Invalid URL format
```

**原因**:
- URLにスペースや改行が含まれている
- URLが間違っている

**解決方法**:
```
正しいURL（コピー用）:

VPN Client:
http://127.0.0.1:35001

VPN Self-Service:
https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml

⚠️ 前後にスペースがないことを確認
⚠️ httpとhttpsを間違えないこと
```

---

## 2. Terraformデプロイ時の問題

### 問題2-1: AWS認証エラー

**症状**:
```
Error: error configuring Terraform AWS Provider: no valid credential sources
```

**原因**:
- AWS認証が切れている
- 認証情報が設定されていない

**解決方法**:
```bash
# AWS SSOで再認証
aws login

# 認証確認
aws sts get-caller-identity

# 期待される出力:
# {
#     "UserId": "AROAJLUWOHFDR2BNQE36S:y-kalen",
#     "Account": "620360464874",
#     "Arn": "arn:aws:sts::620360464874:assumed-role/..."
# }
```

### 問題2-2: SAMLメタデータファイルが見つからない

**症状**:
```
Error: Error reading file ../metadata/vpn-client-metadata.xml: no such file or directory
```

**原因**:
- SAMLメタデータがダウンロードされていない
- ファイルが正しい場所に配置されていない

**解決方法**:
```bash
# ファイルの存在確認
ls -la ../metadata/

# 期待されるファイル:
# vpn-client-metadata.xml
# vpn-self-service-metadata.xml

# ファイルが存在しない場合
# ステップ1に戻ってSAMLメタデータをダウンロード

# ファイルサイズを確認（0バイトでないこと）
ls -lh ../metadata/*.xml
```

### 問題2-3: ユーザーIDが無効

**症状**:
```
Error: error creating IdentityStore Group Membership: ResourceNotFoundException: User not found
```

**原因**:
- terraform.tfvarsのvpn_user_idsが間違っている
- ユーザーが存在しない

**解決方法**:
```bash
# ユーザーIDを再確認
aws identitystore list-users \
  --identity-store-id d-9067dc092d

# 出力からUser IDをコピー
# 例: "UserId": "b448d448-4061-7023-29b0-8901d5628601"

# terraform.tfvarsを編集
nano terraform/terraform.tfvars

# vpn_user_idsを修正
vpn_user_ids = [
  "b448d448-4061-7023-29b0-8901d5628601"  # 正しいUser ID
]

# 再度デプロイ
terraform apply
```

### 問題2-4: 証明書ファイルが見つからない

**症状**:
```
Error: Error reading file ../certs/server.crt: no such file or directory
```

**原因**:
- 証明書が生成されていない
- 証明書が正しい場所に配置されていない

**解決方法**:
```bash
# 証明書ファイルを確認
ls -la ../certs/

# 必要なファイル:
# ca.crt, ca.key
# server.crt, server.key
# client1.vpn.example.com.crt, client1.vpn.example.com.key

# ファイルが存在しない場合、証明書を生成
cd ..
./scripts/generate-certs.sh

# または
./scripts/generate-certs.ps1  # Windows PowerShell
```

### 問題2-5: デプロイ中にセッションが切れた

**症状**:
```
Error: Credentials were refreshed, but the refreshed credentials are still expired.
```

**原因**:
- AWS SSOセッションの有効期限切れ
- デプロイに時間がかかりすぎた

**解決方法**:
```bash
# AWS認証を再実行
aws login

# Terraformを再実行（既に作成されたリソースはスキップされます）
terraform apply

# 状態を確認
terraform show
```

### 問題2-6: リソースクォータ超過

**症状**:
```
Error: Error creating VPC: VpcLimitExceeded: The maximum number of VPCs has been reached.
```

**原因**:
- AWSアカウントのVPC数が上限に達している

**解決方法**:
```
1. AWS Management Console > VPC > Your VPCs

2. 不要なVPCを削除

3. または、AWS Supportにクォータ引き上げをリクエスト
   - Service Quotas > Amazon VPC > VPCs per Region

4. 再度デプロイ
   terraform apply
```

---

## 3. グループ割り当て時の問題

### 問題3-1: VPN-Usersグループが表示されない

**症状**:
```
グループ一覧にVPN-Usersが表示されない
```

**原因**:
- グループの同期に時間がかかっている
- Terraformデプロイが完了していない

**解決方法**:
```bash
# グループの存在を確認
aws identitystore list-groups \
  --identity-store-id d-9067dc092d \
  --filters AttributePath=DisplayName,AttributeValue=VPN-Users

# グループが存在する場合:
# 1. 数分待つ（最大5分）
# 2. ブラウザをリロード
# 3. IAM Identity Centerからログアウトして再ログイン

# グループが存在しない場合:
# Terraformデプロイを確認
cd terraform
terraform output vpn_users_group_id
```

### 問題3-2: グループ割り当てボタンがグレーアウト

**症状**:
```
「Assign users and groups」ボタンがクリックできない
```

**原因**:
- グループが選択されていない
- 権限が不足している

**解決方法**:
```
1. 「Groups」タブが選択されているか確認

2. VPN-Usersの左側のチェックボックスをクリック

3. チェックマークが表示されることを確認

4. 「Assign users and groups」ボタンが青色になることを確認

5. それでもグレーアウトの場合:
   - IAM Identity Centerの管理者権限を確認
   - 別のブラウザで試す
```

### 問題3-3: グループ割り当てエラー

**症状**:
```
Error: Unable to assign group to application
```

**原因**:
- 一時的なサービスエラー
- ブラウザのキャッシュ問題

**解決方法**:
```
1. ブラウザのキャッシュをクリア
   - Chrome: Ctrl+Shift+Delete
   - Firefox: Ctrl+Shift+Delete
   - Edge: Ctrl+Shift+Delete

2. ブラウザを再起動

3. AWS Management Consoleからログアウトして再ログイン

4. 別のブラウザで試す（Chrome、Firefox、Edgeなど）

5. それでも失敗する場合:
   - 数分待ってから再試行
   - AWS Supportに連絡
```

---

## 4. VPN接続時の問題

### 問題4-1: Self-Service Portalにアクセスできない

**症状**:
```
403 Forbidden
Access Denied
```

**原因**:
- グループ割り当てが完了していない
- ユーザーがVPN-Usersグループに所属していない

**解決方法**:
```bash
# グループメンバーシップを確認
aws identitystore list-group-memberships \
  --identity-store-id d-9067dc092d \
  --group-id $(cd terraform && terraform output -raw vpn_users_group_id)

# ユーザーが表示されない場合:
# 1. terraform.tfvarsを確認
cat terraform/terraform.tfvars

# 2. vpn_user_idsに正しいUser IDが設定されているか確認

# 3. Terraformを再適用
cd terraform
terraform apply

# 4. グループ割り当てを確認（ステップ3）
```

### 問題4-2: SAML認証が失敗する

**症状**:
```
Authentication failed
SAML response validation failed
```

**原因**:
- SAMLメタデータが正しくない
- Attribute Mappingsが不足している
- ユーザーがグループに所属していない

**解決方法**:
```
1. SAML Applicationの設定を確認
   - Application ACS URL: http://127.0.0.1:35001
   - Application SAML audience: urn:amazon:webservices:clientvpn

2. Attribute Mappingsを確認（5個必要）:
   ☑ Subject → ${user:email} (emailAddress)
   ☑ Name → ${user:email} (unspecified)
   ☑ FirstName → ${user:givenName} (unspecified)
   ☑ LastName → ${user:familyName} (unspecified)
   ☑ memberOf → ${user:groups} (unspecified)

3. memberOf属性が特に重要！

4. グループメンバーシップを確認（上記参照）

5. SAMLメタデータを再ダウンロードしてTerraformを再適用
```

### 問題4-3: VPN設定ファイルのインポートに失敗

**症状**:
```
Invalid configuration file
Failed to import profile
```

**原因**:
- 設定ファイルが破損している
- ダウンロードが不完全

**解決方法**:
```
1. Self-Service Portalから設定ファイルを再ダウンロード

2. ファイルサイズを確認（0バイトでないこと）
   - Windows: dir C:\Users\y-kalen\Downloads\
   - Linux: ls -lh ~/Downloads/

3. テキストエディタで開いて内容を確認
   - <ca>タグが含まれているか
   - <cert>タグが含まれているか
   - ファイルの最後まで完全か

4. ブラウザを変えてダウンロード（Chrome、Firefox、Edgeなど）

5. AWS VPN Clientを再起動してインポート
```

### 問題4-4: 接続ボタンをクリックしても反応しない

**症状**:
```
「Connect」ボタンをクリックしても何も起こらない
```

**原因**:
- AWS VPN Clientのバグ
- プロファイルが正しく設定されていない

**解決方法**:
```
1. AWS VPN Clientを再起動

2. プロファイルを削除して再追加
   - File > Manage Profiles
   - プロファイルを選択して「Remove」
   - 「Add Profile」で再追加

3. AWS VPN Clientを最新バージョンに更新
   - Help > Check for Updates

4. OSを再起動

5. AWS VPN Clientを再インストール
```

---

## 5. ネットワーク接続の問題

### 問題5-1: VPN接続後にインターネットにアクセスできない

**症状**:
```
VPN接続は成功するが、Webサイトが開けない
```

**原因**:
- Split-Tunnel設定の問題
- DNSの問題
- ルーティングの問題

**解決方法**:
```
1. Split-Tunnel設定を確認
   AWS Management Console > VPC > Client VPN Endpoints
   > client-vpn-pc-endpoint > Details
   > Split tunnel: Enabled

2. DNSを確認
   # Windows
   ipconfig /all | findstr "DNS"
   
   # Linux/macOS
   cat /etc/resolv.conf

3. ルーティングテーブルを確認
   # Windows
   route print
   
   # Linux/macOS
   netstat -rn

4. VPNを切断して再接続

5. それでも失敗する場合:
   - ローカルのファイアウォール設定を確認
   - アンチウイルスソフトを一時的に無効化して試す
```

### 問題5-2: VPC内のリソースにアクセスできない

**症状**:
```
VPN接続は成功するが、プライベートサブネットにアクセスできない
```

**原因**:
- セキュリティグループの設定問題
- ルートテーブルの設定問題
- NACLの設定問題

**解決方法**:
```bash
# セキュリティグループを確認
cd terraform
terraform output

# AWS Management Consoleで確認
# VPC > Security Groups > vpn-access-sg
# Inbound rules:
# - Type: All traffic
# - Source: 192.168.0.0/16

# ルートテーブルを確認
# VPC > Route Tables > client-vpn-route-table
# Routes:
# - 192.168.0.0/16 → local
# - 0.0.0.0/0 → igw-xxxxx

# VPNエンドポイントのルートを確認
# VPC > Client VPN Endpoints > client-vpn-pc-endpoint
# Route table タブ
# - 192.168.0.0/16 → Target VPC
```

### 問題5-3: 接続が頻繁に切れる

**症状**:
```
VPN接続が数分で切断される
```

**原因**:
- ネットワークの不安定性
- ファイアウォールのタイムアウト
- VPNエンドポイントの問題

**解決方法**:
```
1. ローカルネットワークの安定性を確認
   # インターネット接続をテスト
   ping -c 10 8.8.8.8

2. ファイアウォール設定を確認
   - UDP 443ポートが開いているか
   - VPNトラフィックが許可されているか

3. AWS VPN Clientのログを確認
   # Windows
   C:\Users\y-kalen\AppData\Local\AWSVPNClient\logs\

   # Linux
   ~/.config/AWSVPNClient/logs/

4. CloudWatch Logsでエラーを確認
   /aws/clientvpn/pc-endpoint

5. VPNエンドポイントの状態を確認
   AWS Management Console > VPC > Client VPN Endpoints
   > Status: available
```

---

## 6. 認証の問題

### 問題6-1: IAM Identity Centerのパスワードを忘れた

**症状**:
```
ログインできない
```

**解決方法**:
```
1. IAM Identity Centerのログイン画面で「Forgot password?」をクリック

2. メールアドレスを入力

3. パスワードリセットメールを確認

4. 新しいパスワードを設定

5. 再度ログイン
```

### 問題6-2: MFAデバイスを紛失した

**症状**:
```
MFAコードが入力できない
```

**解決方法**:
```
1. AWS Management Console > IAM Identity Center > Users

2. 該当ユーザーをクリック

3. 「MFA devices」タブ

4. 既存のMFAデバイスを削除

5. 新しいMFAデバイスを登録

6. 再度ログイン
```

### 問題6-3: セッションタイムアウト

**症状**:
```
Session expired
Please log in again
```

**原因**:
- IAM Identity Centerのセッションタイムアウト（デフォルト8時間）

**解決方法**:
```
1. 再度ログイン

2. セッションタイムアウトを延長（管理者のみ）:
   AWS Management Console > IAM Identity Center > Settings
   > Session settings
   > Session duration: 12 hours（最大）

3. 長時間使用する場合は定期的に再認証
```

---

## 7. ログとモニタリング

### 7-1. CloudWatch Logsの確認方法

```
1. AWS Management Console > CloudWatch > Log groups

2. 以下のロググループを確認:
   - /aws/clientvpn/pc-endpoint
   - /aws/clientvpn/mobile-endpoint
   - /aws/cloudtrail/client-vpn

3. 最新のログストリームをクリック

4. エラーメッセージを検索
   - Filter: "ERROR"
   - Filter: "FAILED"
   - Filter: "DENIED"
```

### 7-2. CloudTrailの確認方法

```
1. AWS Management Console > CloudTrail > Event history

2. フィルターを設定:
   - Event name: CreateClientVpnEndpoint
   - Event name: AuthorizeClientVpnIngress
   - Event name: AssociateClientVpnTargetNetwork

3. エラーイベントを確認

4. 詳細を表示してエラー原因を特定
```

### 7-3. VPNエンドポイントの状態確認

```bash
# AWS CLIでVPNエンドポイントを確認
aws ec2 describe-client-vpn-endpoints \
  --region ap-northeast-1

# 期待される出力:
# "State": "available"
# "Status": {
#     "Code": "available"
# }

# エラーがある場合:
# "State": "pending-associate"
# "Status": {
#     "Code": "failed",
#     "Message": "..."
# }
```

### 7-4. 接続ログの分析

**正常な接続ログ**:
```
2026-01-26T10:30:15.123Z Connection established for user y-kalen
2026-01-26T10:30:15.456Z SAML authentication successful
2026-01-26T10:30:15.789Z Client IP assigned: 192.168.0.xxx
2026-01-26T10:30:16.012Z Connection active
```

**エラーログの例**:
```
2026-01-26T10:30:15.123Z Connection attempt from user y-kalen
2026-01-26T10:30:15.456Z SAML authentication failed: User not in authorized group
2026-01-26T10:30:15.789Z Connection denied
```

---

## 📞 サポート

### 社内サポート

```
問題が解決しない場合:
1. このトラブルシューティングガイドを確認
2. ../troubleshooting.md（メインドキュメント）を確認
3. CloudWatch Logsでエラーログを確認
4. 社内のインフラチームに連絡
```

### AWSサポート

```
AWSサポートに連絡する場合、以下の情報を準備:
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

## 🔧 よくある質問（FAQ）

### Q1: Terraformで作成したリソースを削除するには？

```bash
cd terraform
terraform destroy

# 確認プロンプトで "yes" を入力
```

**⚠️ 警告**: すべてのVPNインフラストラクチャが削除されます！

### Q2: 新しいユーザーを追加するには？

```bash
# terraform.tfvarsを編集
nano terraform/terraform.tfvars

# vpn_user_idsに新しいユーザーIDを追加
vpn_user_ids = [
  "b448d448-4061-7023-29b0-8901d5628601",  # y-kalen
  "new-user-id-here"                       # 新しいユーザー
]

# 適用
terraform apply
```

### Q3: VPNエンドポイントのログ保持期間は？

```
デフォルト: 30日間

変更方法:
AWS Management Console > CloudWatch > Log groups
> /aws/clientvpn/pc-endpoint
> Actions > Edit retention setting
> 選択: 1 week, 1 month, 3 months, 6 months, 1 year, Never expire
```

### Q4: VPN接続の同時接続数の上限は？

```
デフォルト: 50接続

確認方法:
AWS Management Console > VPC > Client VPN Endpoints
> client-vpn-pc-endpoint > Details
> Max connections: 50

変更方法:
terraform/client_vpn_pc.tf を編集
max_connections = 100  # 希望の値

terraform apply
```

---

**作成日**: 2025年1月26日  
**最終更新**: 2025年1月26日  
**バージョン**: 1.0.0
