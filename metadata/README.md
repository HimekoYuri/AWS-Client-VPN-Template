# SAMLメタデータディレクトリ

このディレクトリには、IAM Identity Center から取得した SAML メタデータファイルを格納します。

## メタデータファイル構成

```
metadata/
├── vpn-client-metadata.xml          # VPN Client用SAMLメタデータ
└── vpn-self-service-metadata.xml    # VPN Self-Service Portal用SAMLメタデータ
```

## メタデータの取得方法

1. **IAM Identity Center コンソールにアクセス**
   - AWS Management Console にログイン
   - IAM Identity Center サービスに移動

2. **SAML Application を作成**
   - 「Applications」→「Add application」をクリック
   - 「Custom SAML 2.0 application」を選択

3. **VPN Client Application の設定**
   - Display Name: `VPN Client`
   - Application ACS URL: `http://127.0.0.1:35001`
   - Application SAML Audience: `urn:amazon:webservices:clientvpn`

4. **メタデータのダウンロード**
   - Application の詳細画面で「IAM Identity Center metadata」をクリック
   - ダウンロードしたファイルを `vpn-client-metadata.xml` として保存

5. **VPN Self-Service Portal Application の設定**
   - Display Name: `VPN Client Self Service`
   - Application Start URL: `https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml`
   - メタデータを `vpn-self-service-metadata.xml` として保存

詳細な手順は `docs/iam-identity-center-setup.md` を参照してください。

## セキュリティ上の注意事項

### ⚠️ 重要：メタデータの取り扱い

- **SAMLメタデータファイル（*.xml）はGitにコミットしないでください**
- `.gitignore` でメタデータファイルが除外されていることを確認してください
- メタデータには組織の認証情報が含まれているため、慎重に取り扱ってください
- メタデータファイルのアクセス権限を制限してください（例: `chmod 600 *.xml`）

## Terraformでの使用

メタデータファイルは Terraform の `file()` 関数で読み込まれます：

```hcl
resource "aws_iam_saml_provider" "vpn_client" {
  name                   = "aws-client-vpn"
  saml_metadata_document = file("${path.module}/metadata/vpn-client-metadata.xml")
}

resource "aws_iam_saml_provider" "vpn_self_service" {
  name                   = "aws-client-vpn-self-service"
  saml_metadata_document = file("${path.module}/metadata/vpn-self-service-metadata.xml")
}
```

## トラブルシューティング

### メタデータファイルが見つからない

```
Error: Error reading file: open metadata/vpn-client-metadata.xml: no such file or directory
```

**解決方法**: IAM Identity Center からメタデータをダウンロードし、正しいファイル名で保存してください。

### メタデータフォーマットエラー

```
Error: InvalidInput: SAML metadata document is not valid
```

**解決方法**: メタデータファイルが正しいXML形式であることを確認してください。ブラウザでファイルを開いて構文エラーがないか確認してください。
