# VPN接続手順書（PC用）

このドキュメントでは、PC用Client VPNエンドポイント（SAML + MFA認証）への接続手順を説明します。

## 📋 目次

- [前提条件](#前提条件)
- [AWS VPN Clientのインストール](#aws-vpn-clientのインストール)
- [VPN設定ファイルの取得](#vpn設定ファイルの取得)
- [VPN接続の設定](#vpn接続の設定)
- [VPN接続の確立](#vpn接続の確立)
- [接続の確認](#接続の確認)
- [トラブルシューティング](#トラブルシューティング)

## 前提条件

### 必要なもの

- ✅ **IAM Identity Centerアカウント**: VPNアクセスグループに所属していること
- ✅ **MFAデバイス**: 多要素認証デバイスが登録されていること
- ✅ **インターネット接続**: VPNエンドポイントに接続できること
- ✅ **管理者権限**: AWS VPN Clientのインストールに必要

### 対応OS

- Windows 10/11 (64-bit)
- macOS 10.15 (Catalina) 以降
- Ubuntu 18.04 LTS 以降

## AWS VPN Clientのインストール

### Windows

1. [AWS VPN Client ダウンロードページ](https://aws.amazon.com/vpn/client-vpn-download/)にアクセス
2. **Windows 64-bit**版をダウンロード
3. ダウンロードした`.msi`ファイルを実行
4. インストールウィザードに従ってインストール
5. インストール完了後、PCを再起動

### macOS

1. [AWS VPN Client ダウンロードページ](https://aws.amazon.com/vpn/client-vpn-download/)にアクセス
2. **macOS**版をダウンロード
3. ダウンロードした`.pkg`ファイルを実行
4. インストールウィザードに従ってインストール
5. システム環境設定 > セキュリティとプライバシー で「AWS VPN Client」を許可

### Linux (Ubuntu)

```bash
# パッケージをダウンロード
wget https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_amd64.deb

# インストール
sudo dpkg -i awsvpnclient_amd64.deb

# 依存関係を解決
sudo apt-get install -f
```

## VPN設定ファイルの取得

### 方法1: Self-Service Portalから取得（推奨）

1. ブラウザで以下のURLにアクセス：
   ```
   https://self-service.clientvpn.amazonaws.com/endpoints/<VPN_ENDPOINT_ID>
   ```
   
   ⚠️ `<VPN_ENDPOINT_ID>`は、インフラ管理者から提供されます。

2. **IAM Identity Centerでログイン**
   - ユーザー名とパスワードを入力
   - MFAコードを入力

3. **設定ファイルをダウンロード**
   - 「Download Client Configuration」ボタンをクリック
   - `downloaded-client-config.ovpn`ファイルが保存されます

### 方法2: 管理者から取得

インフラ管理者から`.ovpn`設定ファイルを受け取ります。

⚠️ **セキュリティ注意**: 設定ファイルは機密情報を含むため、安全な方法（暗号化されたメール、セキュアなファイル共有）で受け取ってください。

## VPN接続の設定

### ステップ1: AWS VPN Clientを起動

- **Windows**: スタートメニューから「AWS VPN Client」を起動
- **macOS**: アプリケーションフォルダから「AWS VPN Client」を起動
- **Linux**: ターミナルで`awsvpnclient`を実行

### ステップ2: プロファイルの追加

1. AWS VPN Clientのメイン画面で「**File**」→「**Manage Profiles**」をクリック

2. 「**Add Profile**」ボタンをクリック

3. プロファイル情報を入力：
   - **Display Name**: `PC VPN (SAML)`（任意の名前）
   - **VPN Configuration File**: ダウンロードした`.ovpn`ファイルを選択

4. 「**Add Profile**」ボタンをクリック

### ステップ3: プロファイルの確認

プロファイルリストに「PC VPN (SAML)」が表示されることを確認します。

## VPN接続の確立

### ステップ1: プロファイルを選択

AWS VPN Clientのメイン画面で「**PC VPN (SAML)**」プロファイルを選択します。

### ステップ2: 接続開始

「**Connect**」ボタンをクリックします。

### ステップ3: SAML認証

1. **ブラウザが自動的に起動**します
   
   ⚠️ ブラウザが起動しない場合は、手動でURLを開いてください。

2. **IAM Identity Centerログイン画面**が表示されます
   - ユーザー名を入力
   - パスワードを入力
   - 「**Sign in**」をクリック

3. **MFA認証**
   - MFAデバイス（Authenticatorアプリ、SMSなど）からコードを取得
   - MFAコードを入力
   - 「**Verify**」をクリック

4. **認証成功**
   - 「Authentication successful」メッセージが表示されます
   - ブラウザを閉じてください

### ステップ4: 接続完了

AWS VPN Clientに戻ると、接続ステータスが「**Connected**」に変わります。

✅ **接続成功！**

## 接続の確認

### 方法1: AWS VPN Clientで確認

AWS VPN Clientのメイン画面で以下を確認：

- **Status**: Connected（緑色）
- **IP Address**: 割り当てられたVPN IPアドレス（172.16.x.x）
- **Duration**: 接続時間

### 方法2: コマンドラインで確認

#### Windows (PowerShell)

```powershell
# VPNインターフェースを確認
Get-NetAdapter | Where-Object {$_.InterfaceDescription -like "*AWS VPN*"}

# 送信元IPアドレスを確認（Elastic IP）
Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing | Select-Object -ExpandProperty Content
```

#### macOS / Linux

```bash
# VPNインターフェースを確認
ifconfig | grep -A 5 "utun"

# 送信元IPアドレスを確認（Elastic IP）
curl https://api.ipify.org
```

返されるIPアドレスが、NAT GatewayのElastic IPと一致することを確認してください。

### 方法3: ブラウザで確認

ブラウザで以下のサイトにアクセス：

- https://www.whatismyip.com/
- https://ipinfo.io/

表示されるIPアドレスが、NAT GatewayのElastic IPと一致することを確認してください。

## VPN接続の切断

1. AWS VPN Clientのメイン画面で「**Disconnect**」ボタンをクリック
2. 接続ステータスが「**Disconnected**」に変わることを確認

## 自動接続の設定（オプション）

### Windows

1. AWS VPN Clientで「**File**」→「**Manage Profiles**」をクリック
2. プロファイルを選択して「**Edit**」をクリック
3. 「**Connect on startup**」にチェックを入れる
4. 「**Save**」をクリック

### macOS

1. AWS VPN Clientで「**Preferences**」を開く
2. 「**General**」タブで「**Launch AWS VPN Client on startup**」にチェック
3. 「**Manage Profiles**」でプロファイルを選択
4. 「**Connect on startup**」にチェックを入れる

## トラブルシューティング

### 問題1: ブラウザが起動しない

**症状**: 「Connect」をクリックしてもブラウザが起動しない

**解決方法**:
1. デフォルトブラウザが設定されているか確認
2. ファイアウォールがブラウザをブロックしていないか確認
3. AWS VPN Clientを再起動

### 問題2: SAML認証に失敗する

**症状**: 「Authentication failed」エラーが表示される

**解決方法**:
1. **ユーザー名・パスワードを確認**
   - IAM Identity Centerの認証情報が正しいか確認
   
2. **MFAコードを確認**
   - MFAデバイスの時刻が正確か確認
   - 新しいMFAコードを生成して再試行
   
3. **グループメンバーシップを確認**
   - IAM Identity CenterでVPNアクセスグループに所属しているか確認
   - インフラ管理者に連絡

### 問題3: 接続が確立されない

**症状**: 「Connecting...」のまま接続が完了しない

**解決方法**:
1. **ネットワーク接続を確認**
   - インターネット接続が正常か確認
   - ファイアウォールがUDP 443をブロックしていないか確認
   
2. **VPNエンドポイントのステータスを確認**
   - インフラ管理者にVPNエンドポイントが正常稼働しているか確認
   
3. **設定ファイルを再取得**
   - Self-Service Portalから最新の設定ファイルをダウンロード
   - プロファイルを削除して再作成

### 問題4: 接続後にインターネットにアクセスできない

**症状**: VPN接続は成功するが、Webサイトにアクセスできない

**解決方法**:
1. **DNSを確認**
   ```bash
   # Windows
   nslookup google.com
   
   # macOS / Linux
   dig google.com
   ```
   
2. **ルーティングを確認**
   ```bash
   # Windows
   route print
   
   # macOS / Linux
   netstat -rn
   ```
   
3. **Split Tunnelを確認**
   - Split Tunnelが有効な場合、VPN経由でアクセスするのは特定のネットワークのみ
   - インフラ管理者に設定を確認

### 問題5: 「Certificate validation failed」エラー

**症状**: 証明書検証エラーが表示される

**解決方法**:
1. **システム時刻を確認**
   - PCの時刻が正確か確認
   - タイムゾーンが正しいか確認
   
2. **証明書の有効期限を確認**
   - インフラ管理者にサーバー証明書の有効期限を確認
   
3. **設定ファイルを再取得**
   - 証明書が更新された可能性があるため、最新の設定ファイルを取得

## セキュリティのベストプラクティス

### 接続時の注意事項

- ✅ **公共Wi-Fiでの使用**: VPN接続により通信が暗号化されるため、公共Wi-Fiでも安全に使用できます
- ✅ **自動切断**: 長時間使用しない場合は、VPN接続を切断してください
- ⚠️ **設定ファイルの管理**: `.ovpn`ファイルは機密情報を含むため、安全に保管してください
- ⚠️ **パスワード管理**: IAM Identity Centerのパスワードは定期的に変更してください

### セッション管理

- VPN接続は**12時間**で自動的に切断されます
- 再接続時は、再度SAML認証が必要です
- MFAデバイスを常に携帯してください

## サポート

問題が解決しない場合は、以下の情報を添えてインフラチームに連絡してください：

### 必要な情報

1. **エラーメッセージ**: スクリーンショットまたはテキスト
2. **OS情報**: Windows/macOS/Linuxのバージョン
3. **AWS VPN Clientバージョン**: ヘルプ→バージョン情報
4. **接続ログ**: AWS VPN Clientのログファイル
   - Windows: `C:\Users\<username>\AppData\Local\AWSVPNClient\logs`
   - macOS: `~/Library/Application Support/AWSVPNClient/logs`
   - Linux: `~/.config/AWSVPNClient/logs`

### 連絡先

- **インフラチーム**: infrastructure@example.com
- **ヘルプデスク**: helpdesk@example.com

---

**作成日**: 2024年
**最終更新**: 2024年
**バージョン**: 1.0.0
