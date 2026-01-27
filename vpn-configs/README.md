# VPN設定ファイル

このディレクトリには、AWS Client VPNの接続設定ファイル（.ovpnファイル）が格納されています。

## 📁 ファイル一覧

### モバイル用VPN設定ファイル
- **mobile-vpn-config.ovpn** - モバイルデバイス（iOS/Android）用のVPN接続設定ファイル

## 🔐 セキュリティ注意事項

### ⚠️ 重要な警告

このディレクトリに含まれる`.ovpn`ファイルには、以下の機密情報が含まれています：

- **クライアント証明書** (`<cert>`セクション)
- **クライアント秘密鍵** (`<key>`セクション)
- **CA証明書** (`<ca>`セクション)
- **VPNエンドポイントのDNS名**

### 取り扱い上の注意

1. **Gitへのコミット禁止**
   - `.ovpn`ファイルは`.gitignore`で除外されています
   - 絶対にGitリポジトリにコミットしないでください

2. **ファイルの配布**
   - 暗号化された通信手段（社内チャット、暗号化メールなど）を使用してください
   - 公開されたチャンネルやメールでの送信は避けてください

3. **アクセス権限の制限**
   - ファイルのアクセス権限を適切に設定してください
   - Linux/macOS: `chmod 600 *.ovpn`
   - Windows: ファイルのプロパティから適切なアクセス権限を設定

4. **定期的な更新**
   - 証明書の有効期限が切れる前に、新しい設定ファイルを生成してください
   - ユーザーが退職した場合は、証明書を失効させてください

## 📱 使用方法

### iOS/Android

1. **OpenVPN Connectアプリのインストール**
   - iOS: [App Store](https://apps.apple.com/app/openvpn-connect/id590379981)
   - Android: [Google Play](https://play.google.com/store/apps/details?id=net.openvpn.openvpn)

2. **設定ファイルのインポート**
   - `mobile-vpn-config.ovpn`をスマートフォンに転送
   - OpenVPN Connectアプリで「Import Profile」を選択
   - ファイルを選択してインポート

3. **VPN接続**
   - インポートしたプロファイルを選択
   - 接続ボタンをタップ
   - 証明書で自動認証され、接続完了

### 詳細な手順

詳しい接続手順は、以下のドキュメントを参照してください：
- [04-vpn-connection-mobile.md](../docs/04-vpn-connection-mobile.md)

## 🔄 設定ファイルの生成方法

新しいクライアント用の設定ファイルを生成する場合は、以下の手順に従ってください：

### 1. VPNエンドポイントから基本設定をエクスポート

```bash
# VPNエンドポイントIDを確認
terraform output vpn_mobile_endpoint_id

# 設定ファイルをエクスポート
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id <endpoint-id> \
  --region ap-northeast-1 \
  --output text > mobile-vpn-config-new.ovpn
```

### 2. クライアント証明書を生成

```bash
# easy-rsaディレクトリに移動
cd ../easy-rsa/easyrsa3

# 新しいクライアント証明書を生成
./easyrsa build-client-full client2.vpn.example.com nopass

# 証明書をcertsディレクトリにコピー
cd ../../
cp easy-rsa/easyrsa3/pki/issued/client2.vpn.example.com.crt certs/
cp easy-rsa/easyrsa3/pki/private/client2.vpn.example.com.key certs/
```

### 3. 証明書を設定ファイルに追加

```bash
# 設定ファイルに証明書を追加
cat >> vpn-configs/mobile-vpn-config-new.ovpn << EOF

<cert>
$(cat certs/client2.vpn.example.com.crt)
</cert>

<key>
$(cat certs/client2.vpn.example.com.key)
</key>
EOF
```

### 4. 設定ファイルの検証

```bash
# 設定ファイルの内容を確認
cat vpn-configs/mobile-vpn-config-new.ovpn

# 以下のセクションが含まれていることを確認
# - remote (VPNエンドポイントのDNS名)
# - <ca> (CA証明書)
# - <cert> (クライアント証明書)
# - <key> (クライアント秘密鍵)
```

## 🗑️ 証明書の失効

ユーザーが退職した場合や、秘密鍵が漏洩した場合は、証明書を失効させる必要があります。

```bash
# easy-rsaディレクトリに移動
cd easy-rsa/easyrsa3

# 証明書を失効
./easyrsa revoke client1.vpn.example.com

# CRL（Certificate Revocation List）を生成
./easyrsa gen-crl

# CRLをVPNエンドポイントに適用（Terraformで設定）
# terraform/client_vpn_mobile.tf の revocation_list を更新
```

## 📞 サポート

問題が発生した場合は、以下のドキュメントを参照してください：
- [06-troubleshooting.md](../docs/06-troubleshooting.md) - トラブルシューティングガイド
- [05-security-maintenance.md](../docs/05-security-maintenance.md) - セキュリティメンテナンス

## 📚 関連ドキュメント

- [01-easy-rsa-setup.md](../docs/01-easy-rsa-setup.md) - 証明書生成ツールのセットアップ
- [03-deployment-guide.md](../docs/03-deployment-guide.md) - Terraformデプロイメントガイド
- [04-vpn-connection-mobile.md](../docs/04-vpn-connection-mobile.md) - モバイルVPN接続手順

---

**最終更新日**: 2026年1月28日  
**バージョン**: 1.0.0
