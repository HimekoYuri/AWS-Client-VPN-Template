# ステップ4: VPN接続テスト

## 📋 このステップでやること

実際にVPN接続をテストして、正常に動作することを確認します。

**所要時間**: 約10分

## 🎯 テストする内容

1. **PC用VPN接続テスト** - SAML認証でVPN接続
2. **Self-Service Portalアクセステスト** - 設定ファイルダウンロード
3. **接続後の疎通確認** - プライベートサブネットへのアクセス

---

## 📝 パート1: Self-Service Portalから設定ファイルをダウンロード

### 1-1. Self-Service Portal URLを取得

#### ターミナルで取得

```bash
cd /mnt/d/CloudDrive/Google/Client-VPN-test/terraform

# Self-Service Portal URLを表示
terraform output vpn_pc_self_service_url
```

**出力例**:
```
https://self-service.clientvpn.amazonaws.com/endpoints/cvpn-endpoint-xxxxx
```

### 1-2. Self-Service Portalにアクセス

```
1. ブラウザで上記URLを開く

2. IAM Identity Centerのログイン画面が表示される

3. ユーザー名とパスワードを入力
   - ユーザー名: y-kalen
   - パスワード: （IAM Identity Centerで設定したパスワード）

4. MFAコード（設定している場合）を入力

5. Self-Service Portalのダッシュボードが表示される
```

### 1-3. VPN設定ファイルをダウンロード

```
1. 「Download Client Configuration」ボタンをクリック

2. `downloaded-client-config.ovpn` ファイルがダウンロードされる

3. ファイルを適切な場所に保存
   - Windows: C:\Users\y-kalen\Documents\VPN\
   - Linux: ~/Documents/VPN/
```

**⚠️ 重要**: このファイルには認証情報が含まれているため、安全に保管してください。

---

## 📝 パート2: AWS VPN Clientのインストール

### 2-1. AWS VPN Clientをダウンロード

#### Windowsの場合

```
1. ブラウザで以下のURLを開く:
   https://aws.amazon.com/vpn/client-vpn-download/

2. 「Download for Windows」をクリック

3. インストーラーをダウンロード
   - ファイル名: AWSVPNClient.msi
```

#### macOSの場合

```
1. 上記URLから「Download for macOS」をクリック

2. インストーラーをダウンロード
   - ファイル名: AWSVPNClient.pkg
```

#### Linuxの場合

```bash
# Ubuntu/Debian
wget https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_amd64.deb
sudo dpkg -i awsvpnclient_amd64.deb

# Fedora/RHEL
wget https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_x86_64.rpm
sudo rpm -i awsvpnclient_x86_64.rpm
```

### 2-2. AWS VPN Clientをインストール

#### Windowsの場合

```
1. ダウンロードした AWSVPNClient.msi をダブルクリック

2. インストールウィザードに従ってインストール

3. 「Next」→「Install」→「Finish」

4. スタートメニューから「AWS VPN Client」を起動
```

#### macOSの場合

```
1. ダウンロードした AWSVPNClient.pkg をダブルクリック

2. インストールウィザードに従ってインストール

3. Applicationsフォルダから「AWS VPN Client」を起動
```

---

## 📝 パート3: VPN接続設定

### 3-1. AWS VPN Clientを起動

```
1. AWS VPN Clientを起動

2. 初回起動時は利用規約が表示される

3. 「Accept」をクリック
```

### 3-2. VPNプロファイルを追加

```
1. 「File」メニュー → 「Manage Profiles」をクリック

2. 「Add Profile」をクリック

3. 以下の情報を入力:
   - Display Name: AWS Client VPN - PC
   - VPN Configuration File: （ダウンロードした downloaded-client-config.ovpn を選択）

4. 「Add Profile」ボタンをクリック
```

**スクリーンショット参考**:
```
┌─────────────────────────────────────┐
│ Add Profile                         │
├─────────────────────────────────────┤
│ Display Name *                      │
│ AWS Client VPN - PC                 │
├─────────────────────────────────────┤
│ VPN Configuration File *            │
│ [Browse...] downloaded-client-co... │
├─────────────────────────────────────┤
│         [Cancel]  [Add Profile]     │
└─────────────────────────────────────┘
```

### 3-3. プロファイルの確認

```
1. プロファイル一覧に「AWS Client VPN - PC」が表示される

2. 「Done」をクリック
```

---

## 📝 パート4: VPN接続テスト

### 4-1. VPN接続を開始

```
1. AWS VPN Clientのメイン画面で「AWS Client VPN - PC」を選択

2. 「Connect」ボタンをクリック

3. ブラウザが開き、IAM Identity Centerのログイン画面が表示される
```

### 4-2. SAML認証

```
1. ユーザー名とパスワードを入力
   - ユーザー名: y-kalen
   - パスワード: （IAM Identity Centerで設定したパスワード）

2. MFAコード（設定している場合）を入力

3. 「Sign in」をクリック

4. 認証成功メッセージが表示される
```

### 4-3. 接続完了の確認

**AWS VPN Clientの表示**:
```
Status: Connected
Duration: 00:00:15
Bytes Sent: 1.2 KB
Bytes Received: 2.5 KB
```

**✅ 確認ポイント**:
- Status が「Connected」になっている
- 緑色のチェックマークが表示されている

---

## 📝 パート5: 接続後の疎通確認

### 5-1. VPN経由のIPアドレスを確認

#### Windowsの場合

```powershell
# PowerShellを開く
ipconfig

# VPNインターフェースを確認
# 「AWS VPN Client」という名前のアダプターを探す
```

**期待される出力**:
```
Ethernet adapter AWS VPN Client:

   Connection-specific DNS Suffix  . :
   IPv4 Address. . . . . . . . . . . : 192.168.0.xxx
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . : 192.168.0.1
```

#### Linux/macOSの場合

```bash
# VPNインターフェースを確認
ifconfig | grep -A 5 tun

# または
ip addr show | grep -A 5 tun
```

### 5-2. VPC内のリソースへの疎通確認

```bash
# プライベートサブネットのIPアドレスにping
ping 192.168.2.10

# 期待される出力:
# 64 bytes from 192.168.2.10: icmp_seq=1 ttl=64 time=5.2 ms
```

**⚠️ 注意**: プライベートサブネットにEC2インスタンスなどのリソースがない場合、pingは失敗します。

### 5-3. インターネット接続の確認

```bash
# 外部サイトへのアクセス確認
curl -I https://www.google.com

# 期待される出力:
# HTTP/2 200
# content-type: text/html; charset=ISO-8859-1
```

**✅ 確認ポイント**:
- VPN経由でインターネットにアクセスできる
- Split-Tunnel設定により、VPCへのトラフィックのみVPN経由

---

## 📝 パート6: CloudWatch Logsでログ確認

### 6-1. AWS Management Consoleでログを確認

```
1. AWS Management Console > CloudWatch > Log groups

2. 以下のロググループを探す:
   - /aws/clientvpn/pc-endpoint
   - /aws/clientvpn/mobile-endpoint

3. 「pc-endpoint」をクリック

4. 最新のログストリームをクリック

5. 接続ログを確認
```

### 6-2. 接続ログの確認

**期待されるログ**:
```
2026-01-26T10:30:15.123Z Connection established for user y-kalen
2026-01-26T10:30:15.456Z SAML authentication successful
2026-01-26T10:30:15.789Z Client IP assigned: 192.168.0.xxx
2026-01-26T10:30:16.012Z Connection active
```

**✅ 確認ポイント**:
- `Connection established` が記録されている
- `SAML authentication successful` が記録されている
- エラーログがない

---

## 📝 パート7: VPN切断

### 7-1. VPN接続を切断

```
1. AWS VPN Clientのメイン画面で「Disconnect」ボタンをクリック

2. Status が「Disconnected」になることを確認

3. 切断完了
```

### 7-2. 切断ログの確認

```
1. CloudWatch Logs > /aws/clientvpn/pc-endpoint

2. 最新のログストリームを確認

3. 切断ログを確認
```

**期待されるログ**:
```
2026-01-26T10:45:30.123Z Connection terminated by user
2026-01-26T10:45:30.456Z Session duration: 15 minutes
2026-01-26T10:45:30.789Z Bytes sent: 1.2 MB, Bytes received: 3.5 MB
```

---

## ✅ 完了確認

### チェックリスト

```
パート1: Self-Service Portal
☑ Self-Service Portal URLを取得
☑ ブラウザでアクセス
☑ IAM Identity Centerでログイン成功
☑ VPN設定ファイルをダウンロード

パート2: AWS VPN Clientインストール
☑ AWS VPN Clientをダウンロード
☑ インストール完了
☑ アプリケーション起動成功

パート3: VPN接続設定
☑ プロファイル追加
☑ 設定ファイルをインポート
☑ プロファイル一覧に表示

パート4: VPN接続テスト
☑ 「Connect」ボタンをクリック
☑ SAML認証成功
☑ Status: Connected

パート5: 疎通確認
☑ VPN IPアドレス取得確認
☑ VPC内リソースへの疎通確認（オプション）
☑ インターネット接続確認

パート6: ログ確認
☑ CloudWatch Logsにアクセス
☑ 接続ログ確認
☑ エラーログなし

パート7: VPN切断
☑ 「Disconnect」ボタンをクリック
☑ Status: Disconnected
☑ 切断ログ確認
```

---

## 🔧 トラブルシューティング

### エラー1: Self-Service Portalにアクセスできない

**エラーメッセージ**:
```
403 Forbidden
```

**原因**: グループ割り当てが完了していない

**解決方法**:
1. ステップ3に戻ってグループ割り当てを確認
2. VPN-UsersグループがVPN Client Self Service Applicationに割り当てられているか確認
3. 数分待ってから再度アクセス

### エラー2: SAML認証が失敗する

**エラーメッセージ**:
```
Authentication failed
```

**原因**: ユーザーがVPN-Usersグループに所属していない

**解決方法**:
```bash
# グループメンバーシップを確認
aws identitystore list-group-memberships \
  --identity-store-id d-9067dc092d \
  --group-id $(cd terraform && terraform output -raw vpn_users_group_id)

# ユーザーが表示されない場合、terraform.tfvarsを確認
cat terraform/terraform.tfvars

# vpn_user_idsに正しいUser IDが設定されているか確認
```

### エラー3: VPN接続後にインターネットにアクセスできない

**原因**: Split-Tunnel設定の問題

**解決方法**:
```
1. AWS Management Console > VPC > Client VPN Endpoints

2. 「client-vpn-pc-endpoint」をクリック

3. 「Split tunnel」が「Enabled」になっているか確認

4. 「Route table」タブで以下のルートを確認:
   - 192.168.0.0/16 → VPC
   - 0.0.0.0/0 → Internet Gateway（存在しない場合は正常）
```

### エラー4: 設定ファイルのインポートに失敗

**エラーメッセージ**:
```
Invalid configuration file
```

**原因**: 設定ファイルが破損している

**解決方法**:
1. Self-Service Portalから設定ファイルを再ダウンロード
2. ファイルサイズが0バイトでないか確認
3. テキストエディタで開いて内容を確認（`<ca>`タグなどが含まれているか）

### エラー5: 接続は成功するがVPC内にアクセスできない

**原因**: セキュリティグループまたはルートテーブルの設定問題

**解決方法**:
```bash
# セキュリティグループを確認
cd terraform
terraform output

# AWS Management Consoleで確認
# VPC > Security Groups > vpn-access-sg
# Inbound rules: 192.168.0.0/16 からのすべてのトラフィックを許可
```

---

## 📝 補足情報

### VPN接続の仕組み

```
ユーザー（y-kalen）
  ↓
AWS VPN Client
  ↓
SAML認証（IAM Identity Center）
  ↓
VPN-Usersグループの確認
  ↓
VPNエンドポイント（cvpn-endpoint-xxxxx）
  ↓
VPC（192.168.0.0/16）
  ↓
プライベートサブネット（192.168.2.0/24, 192.168.3.0/24）
```

### Split-Tunnel設定

このVPN設定では**Split-Tunnel**が有効になっています：

- **VPC宛のトラフィック（192.168.0.0/16）**: VPN経由
- **インターネット宛のトラフィック**: ローカルのインターネット接続を使用

**メリット**:
- インターネット速度が低下しない
- VPNサーバーの負荷が軽減される
- 必要なトラフィックのみVPN経由

### モバイル用VPN接続（証明書認証）

モバイルデバイス（iOS/Android）からVPN接続する場合:

1. **証明書ベースの認証**を使用
2. 設定手順は `../vpn-connection-mobile.md` を参照
3. VPNエンドポイント: `client-vpn-mobile-endpoint`

---

## 🎉 ステップ4完了！

VPN接続テストが完了しました。正常に動作していることを確認できました！

次のステップ: [troubleshooting.md](troubleshooting.md)（トラブルシューティングガイド）

---

**作成日**: 2025年1月26日  
**最終更新**: 2025年1月26日  
**バージョン**: 1.0.0
