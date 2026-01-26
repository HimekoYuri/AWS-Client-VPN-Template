# easy-rsa セットアップガイド

このドキュメントでは、AWS Client VPNで使用する証明書を生成するためのeasy-rsaのセットアップ手順を説明します。

## 目次

1. [概要](#概要)
2. [前提条件](#前提条件)
3. [自動セットアップ（推奨）](#自動セットアップ推奨)
4. [手動セットアップ](#手動セットアップ)
5. [証明書の確認](#証明書の確認)
6. [トラブルシューティング](#トラブルシューティング)
7. [セキュリティ注意事項](#セキュリティ注意事項)

## 概要

AWS Client VPNでは、サーバー証明書とクライアント証明書が必要です。本プロジェクトでは、コスト削減のため、AWS Private CA（月額$400）の代わりに、OpenSSLベースのeasy-rsaツールを使用して自己署名証明書を作成します。

### 生成される証明書

| ファイル名 | 説明 | 用途 |
|-----------|------|------|
| `ca.crt` | ルートCA証明書 | 証明書チェーンの検証 |
| `ca.key` | ルートCA秘密鍵 | 新しい証明書の署名（**機密**） |
| `server.crt` | サーバー証明書 | VPNエンドポイントの認証 |
| `server.key` | サーバー秘密鍵 | VPNエンドポイントの暗号化（**機密**） |
| `client1.vpn.example.com.crt` | クライアント証明書 | スマホVPNクライアントの認証 |
| `client1.vpn.example.com.key` | クライアント秘密鍵 | スマホVPNクライアントの暗号化（**機密**） |

## 前提条件

### Windows環境

- **Git for Windows** がインストールされていること
  - ダウンロード: https://git-scm.com/download/win
  - Git Bashが含まれています

### Linux/macOS環境

- **Git** がインストールされていること
  ```bash
  # Ubuntu/Debian
  sudo apt-get install git
  
  # macOS (Homebrew)
  brew install git
  ```

### 共通

- インターネット接続があること（easy-rsaのダウンロード用）
- プロジェクトルートディレクトリで作業すること

## 自動セットアップ（推奨）

自動セットアップスクリプトを使用すると、easy-rsaのダウンロードから証明書の生成まで、すべての手順を自動で実行できます。

### Windows (PowerShell)

1. PowerShellを**管理者権限で**起動します

2. 実行ポリシーを確認します
   ```powershell
   Get-ExecutionPolicy
   ```

3. 実行ポリシーが`Restricted`の場合は、一時的に変更します
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
   ```

4. プロジェクトルートディレクトリに移動します
   ```powershell
   cd C:\path\to\your\project
   ```

5. スクリプトを実行します
   ```powershell
   .\scripts\generate-certs.ps1
   ```

6. スクリプトが完了すると、`certs/`ディレクトリに証明書が生成されます

### Windows (Git Bash) / Linux / macOS

1. ターミナルを開きます

2. プロジェクトルートディレクトリに移動します
   ```bash
   cd /path/to/your/project
   ```

3. スクリプトに実行権限を付与します
   ```bash
   chmod +x scripts/generate-certs.sh
   ```

4. スクリプトを実行します
   ```bash
   ./scripts/generate-certs.sh
   ```

5. スクリプトが完了すると、`certs/`ディレクトリに証明書が生成されます

## 手動セットアップ

自動スクリプトが使用できない場合や、手動で証明書を生成したい場合は、以下の手順に従ってください。

### ステップ1: easy-rsaのダウンロード

```bash
# プロジェクトルートディレクトリで実行
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3
```

### ステップ2: PKIディレクトリの初期化

```bash
./easyrsa init-pki
```

このコマンドは、証明書と鍵を管理するための`pki/`ディレクトリを作成します。

### ステップ3: CA証明書の作成

```bash
./easyrsa --batch --req-cn="AWS Client VPN CA" build-ca nopass
```

- `--batch`: 対話モードをスキップ
- `--req-cn`: Common Name（証明書の識別名）を指定
- `nopass`: パスワードなしで秘密鍵を作成（自動化のため）

**生成されるファイル:**
- `pki/ca.crt`: CA証明書
- `pki/private/ca.key`: CA秘密鍵

### ステップ4: サーバー証明書の作成

```bash
./easyrsa --batch --req-cn="server" build-server-full server nopass
```

**生成されるファイル:**
- `pki/issued/server.crt`: サーバー証明書
- `pki/private/server.key`: サーバー秘密鍵

### ステップ5: クライアント証明書の作成

```bash
./easyrsa --batch --req-cn="client1.vpn.example.com" build-client-full client1.vpn.example.com nopass
```

**生成されるファイル:**
- `pki/issued/client1.vpn.example.com.crt`: クライアント証明書
- `pki/private/client1.vpn.example.com.key`: クライアント秘密鍵

### ステップ6: 証明書のコピー

証明書をプロジェクトの`certs/`ディレクトリにコピーします。

```bash
# プロジェクトルートに戻る
cd ../../

# 証明書をコピー
cp easy-rsa/easyrsa3/pki/ca.crt certs/
cp easy-rsa/easyrsa3/pki/private/ca.key certs/
cp easy-rsa/easyrsa3/pki/issued/server.crt certs/
cp easy-rsa/easyrsa3/pki/private/server.key certs/
cp easy-rsa/easyrsa3/pki/issued/client1.vpn.example.com.crt certs/
cp easy-rsa/easyrsa3/pki/private/client1.vpn.example.com.key certs/
```

## 証明書の確認

### 証明書ファイルの存在確認

```bash
ls -la certs/
```

以下のファイルが存在することを確認してください：
- `ca.crt`
- `ca.key`
- `server.crt`
- `server.key`
- `client1.vpn.example.com.crt`
- `client1.vpn.example.com.key`

### 証明書の内容確認

OpenSSLを使用して証明書の内容を確認できます。

#### CA証明書の確認

```bash
openssl x509 -in certs/ca.crt -noout -text
```

**重要な情報:**
- Subject: 証明書の所有者
- Issuer: 証明書の発行者（自己署名の場合はSubjectと同じ）
- Validity: 有効期限
- Public Key: 公開鍵のアルゴリズムとサイズ

#### サーバー証明書の確認

```bash
openssl x509 -in certs/server.crt -noout -text
```

#### クライアント証明書の確認

```bash
openssl x509 -in certs/client1.vpn.example.com.crt -noout -text
```

### 証明書チェーンの検証

サーバー証明書がCA証明書で正しく署名されているか確認します。

```bash
openssl verify -CAfile certs/ca.crt certs/server.crt
```

**期待される出力:**
```
certs/server.crt: OK
```

クライアント証明書も同様に検証します。

```bash
openssl verify -CAfile certs/ca.crt certs/client1.vpn.example.com.crt
```

## トラブルシューティング

### エラー: "Git が見つかりません"

**原因:** Gitがインストールされていないか、PATHに追加されていません。

**解決方法:**
1. Git for Windowsをインストール: https://git-scm.com/download/win
2. インストール時に「Git Bash Here」オプションを有効にする
3. PowerShellまたはコマンドプロンプトを再起動

### エラー: "easy-rsa3 ディレクトリが見つかりません"

**原因:** easy-rsaのクローンが失敗したか、ディレクトリ構造が異なります。

**解決方法:**
1. `easy-rsa`ディレクトリを削除
   ```bash
   rm -rf easy-rsa
   ```
2. 再度クローン
   ```bash
   git clone https://github.com/OpenVPN/easy-rsa.git
   ```
3. ディレクトリ構造を確認
   ```bash
   ls -la easy-rsa/
   ```

### エラー: "PKI already exists"

**原因:** PKIディレクトリが既に存在します。

**解決方法:**
1. 既存のPKIディレクトリを削除
   ```bash
   cd easy-rsa/easyrsa3
   rm -rf pki
   ```
2. 再度初期化
   ```bash
   ./easyrsa init-pki
   ```

### エラー: "証明書の検証に失敗しました"

**原因:** 証明書チェーンが正しく構築されていません。

**解決方法:**
1. すべての証明書を削除
   ```bash
   rm -rf easy-rsa/easyrsa3/pki
   rm -f certs/*.crt certs/*.key
   ```
2. 手順を最初からやり直す

### Windows PowerShellで実行ポリシーエラー

**エラーメッセージ:**
```
.\scripts\generate-certs.ps1 : このシステムではスクリプトの実行が無効になっているため、ファイル generate-certs.ps1 を読み込むことができません。
```

**解決方法:**
1. PowerShellを管理者権限で起動
2. 実行ポリシーを一時的に変更
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
   ```
3. スクリプトを再実行

## セキュリティ注意事項

### 秘密鍵の保護

⚠️ **重要:** 秘密鍵ファイル（`*.key`）は絶対にGitにコミットしないでください。

- `.gitignore`で除外されていることを確認してください
  ```
  certs/*.key
  certs/ca.key
  ```

- 秘密鍵ファイルのアクセス権限を制限してください
  ```bash
  chmod 600 certs/*.key
  ```

### 証明書の有効期限

- easy-rsaで生成される証明書のデフォルト有効期限は**10年（3650日）**です
- 本番環境では、より短い有効期限（1〜2年）を設定することを推奨します
- 有効期限を変更する場合は、`easy-rsa/easyrsa3/vars`ファイルを編集してください

### 証明書の失効

ユーザーが退職した場合や、秘密鍵が漏洩した場合は、証明書を失効させる必要があります。

```bash
cd easy-rsa/easyrsa3
./easyrsa revoke client1.vpn.example.com
./easyrsa gen-crl
```

生成されたCRL（Certificate Revocation List）をVPNエンドポイントに適用してください。

### バックアップ

- CA秘密鍵（`ca.key`）は安全な場所にバックアップしてください
- CA秘密鍵を紛失すると、新しい証明書を発行できなくなります
- バックアップは暗号化されたストレージに保存してください

## 次のステップ

証明書の生成が完了したら、以下の手順に進んでください：

1. **Terraformで証明書をACMにインポート**
   - `terraform/acm.tf`ファイルを確認
   - 証明書ファイルのパスが正しいことを確認

2. **Terraformでインフラを構築**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **VPN接続テスト**
   - PC用VPN: `docs/vpn-connection-pc.md`を参照
   - スマホ用VPN: `docs/vpn-connection-mobile.md`を参照

4. **クライアント証明書の配布**
   - `docs/certificate-distribution.md`を参照
   - スマホユーザーに証明書を安全に配布

## 参考資料

- [easy-rsa GitHub Repository](https://github.com/OpenVPN/easy-rsa)
- [easy-rsa Documentation](https://easy-rsa.readthedocs.io/)
- [AWS Client VPN Administrator Guide](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
