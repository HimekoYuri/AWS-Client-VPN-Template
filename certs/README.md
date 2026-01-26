# 証明書管理ディレクトリ

このディレクトリには、AWS Client VPN用の証明書ファイルを格納します。

## 証明書ファイル構成

```
certs/
├── ca.crt              # ルートCA証明書（公開可）
├── ca.key              # ルートCA秘密鍵（⚠️ Gitにコミットしない）
├── server.crt          # サーバー証明書（公開可）
├── server.key          # サーバー秘密鍵（⚠️ Gitにコミットしない）
├── client1.vpn.example.com.crt  # クライアント証明書（公開可）
└── client1.vpn.example.com.key  # クライアント秘密鍵（⚠️ Gitにコミットしない）
```

## 証明書生成方法

証明書は OpenSSL/easy-rsa を使用して生成します。自動生成スクリプトが用意されていますので、環境に応じて選択してください。

### Windows環境（PowerShell）

```powershell
# PowerShellを管理者権限で起動
.\scripts\generate-certs.ps1
```

### Windows環境（Git Bash）/ Linux / macOS

```bash
# 実行権限を付与
chmod +x scripts/generate-certs.sh

# スクリプトを実行
./scripts/generate-certs.sh
```

### 詳細な手順

手動セットアップや詳細な手順については、以下のドキュメントを参照してください：

- **easy-rsaセットアップガイド**: `docs/easy-rsa-setup.md`
- **トラブルシューティング**: `docs/easy-rsa-setup.md#トラブルシューティング`

## セキュリティ上の注意事項

### ⚠️ 重要：秘密鍵の取り扱い

- **秘密鍵（*.key）は絶対にGitにコミットしないでください**
- `.gitignore` で秘密鍵ファイルが除外されていることを確認してください
- 秘密鍵は安全な場所に保管し、アクセス権限を制限してください
- 秘密鍵が漏洩した場合は、直ちに証明書を失効させ、新しい証明書を発行してください

### 証明書の有効期限

- CA証明書: 3650日（10年）
- サーバー証明書: 3650日（10年）
- クライアント証明書: 3650日（10年）

有効期限が近づいたら、証明書を更新してください。更新手順は `docs/security-maintenance.md` を参照してください。

## ACMへのインポート

証明書は Terraform を使用して AWS Certificate Manager (ACM) にインポートされます。

```hcl
resource "aws_acm_certificate" "vpn_server" {
  private_key       = file("${path.module}/certs/server.key")
  certificate_body  = file("${path.module}/certs/server.crt")
  certificate_chain = file("${path.module}/certs/ca.crt")
}
```

## トラブルシューティング

### 証明書フォーマットエラー

証明書が正しいPEM形式であることを確認してください：

```bash
# 証明書の内容を確認
openssl x509 -in server.crt -text -noout

# 秘密鍵の内容を確認
openssl rsa -in server.key -check
```

### 証明書チェーンの検証

証明書チェーンが正しいことを確認してください：

```bash
# 証明書チェーンを検証
openssl verify -CAfile ca.crt server.crt
```
