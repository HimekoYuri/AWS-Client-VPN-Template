# PC版VPN (SAML認証) セットアップ手順

## 前提条件
- IAM Identity Centerが有効化されている
- VPN-Usersグループとvpn-testユーザーが作成済み

## ステップ1: IAM Identity CenterでSAMLアプリケーションを作成

### 1-1. IAM Identity Centerコンソールを開く
https://ap-northeast-1.console.aws.amazon.com/singlesignon/home?region=ap-northeast-1

### 1-2. アプリケーションを追加
1. 左メニューから「**Applications**」を選択
2. 「**Customer managed**」タブを選択
3. 「**Add application**」ボタンをクリック

### 1-3. アプリケーションタイプを選択
1. 「**I have an application I want to set up**」を選択
2. 「**Application type**」で「**SAML 2.0**」を選択
3. 「**Next**」をクリック

### 1-4. アプリケーション詳細を設定

#### Display name
```
AWS-Client-VPN
```

#### Description
```
AWS Client VPN SAML Authentication for PC
```

#### Application start URL (空欄)
```
(空欄のまま)
```

#### Relay state (空欄)
```
(空欄のまま)
```

#### Session duration
```
8 hours
```

「**Next**」をクリック

### 1-5. SAML設定

#### Application ACS URL
```
http://127.0.0.1:35001
```

#### Application SAML audience
```
urn:amazon:webservices:clientvpn
```

「**Next**」をクリック

### 1-6. Attribute mappings

以下の属性マッピングを追加:

| User attribute in IAM Identity Center | Maps to this string value | Format |
|---------------------------------------|---------------------------|--------|
| `${user:email}` | `Subject` | `emailAddress` |
| `${user:email}` | `Name` | `unspecified` |
| `${user:givenName}` | `FirstName` | `unspecified` |
| `${user:familyName}` | `LastName` | `unspecified` |
| `${user:groups}` | `memberOf` | `unspecified` |

**重要**: `memberOf`属性は、VPN-Usersグループによる認可に必要です!

「**Next**」をクリック

### 1-7. アプリケーションを作成
「**Submit**」をクリック

## ステップ2: SAMLメタデータをダウンロード

### 2-1. アプリケーション詳細を開く
1. 作成した「**AWS-Client-VPN**」アプリケーションをクリック
2. 「**Actions**」→「**Edit configuration**」を選択

### 2-2. メタデータファイルをダウンロード
1. 「**IAM Identity Center metadata**」セクションを探す
2. 「**IAM Identity Center SAML metadata file**」の横にある「**Download**」をクリック
3. ダウンロードしたファイルを以下のパスに保存:
   ```
   /mnt/d/CloudDrive/Google/Client-VPN-test/metadata/vpn-client-metadata-real.xml
   ```

## ステップ3: VPN-Usersグループにアクセス権限を付与

### 3-1. アプリケーションにグループを割り当て
1. 「**AWS-Client-VPN**」アプリケーションの詳細画面で
2. 「**Assigned users and groups**」タブを選択
3. 「**Assign users and groups**」をクリック
4. 「**Groups**」タブを選択
5. 「**VPN-Users**」グループにチェック
6. 「**Assign users and groups**」をクリック

## ステップ4: SAMLプロバイダーを更新

メタデータファイルをダウンロードしたら、以下のコマンドを実行:

```bash
cd /mnt/d/CloudDrive/Google/Client-VPN-test/terraform

# メタデータファイルをコピー
cp ../metadata/vpn-client-metadata-real.xml ../metadata/vpn-client-metadata.xml

# Terraformで更新
eval $(aws configure export-credentials --format env)
export AWS_DEFAULT_REGION=ap-northeast-1

# SAMLプロバイダーを更新
terraform apply -target=aws_iam_saml_provider.vpn_client -auto-approve
```

## ステップ5: PC用VPN設定ファイルをダウンロード

```bash
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id cvpn-endpoint-0c0d7aaec47c97031 \
  --region ap-northeast-1 \
  --output text > /mnt/d/CloudDrive/Google/Client-VPN-test/pc-vpn-config-final.ovpn
```

## ステップ6: VPN接続テスト

1. `pc-vpn-config-final.ovpn`をOpenVPN Connectにインポート
2. 接続ボタンをクリック
3. ブラウザが開いてIAM Identity Centerのログイン画面が表示される
4. vpn-testユーザーでログイン
5. 接続成功! ✅

## トラブルシューティング

### "No access"エラーが出る場合
- VPN-Usersグループがアプリケーションに割り当てられているか確認
- vpn-testユーザーがVPN-Usersグループのメンバーか確認
- 属性マッピングで`memberOf`が設定されているか確認

### ブラウザが開かない場合
- OpenVPN Connectが最新版か確認
- ファイアウォールでポート35001が開いているか確認

### 認証後に接続できない場合
- Client VPNエンドポイントの認可ルールを確認:
  ```bash
  aws ec2 describe-client-vpn-authorization-rules \
    --client-vpn-endpoint-id cvpn-endpoint-0c0d7aaec47c97031 \
    --region ap-northeast-1
  ```

## 参考情報

### VPNエンドポイント情報
- **PC VPN Endpoint ID**: cvpn-endpoint-0c0d7aaec47c97031
- **DNS名**: *.cvpn-endpoint-0c0d7aaec47c97031.prod.clientvpn.ap-northeast-1.amazonaws.com
- **クライアントCIDR**: 172.16.0.0/22

### IAM Identity Center情報
- **Instance ARN**: arn:aws:sso:::instance/ssoins-775851192c170650
- **Identity Store ID**: d-9567adbcf1
- **VPN-Users Group ID**: 1794ca98-90d1-70c9-40d1-dbd229b42262
- **vpn-test User ID**: 7784aad8-2051-70b9-491f-89cf9e87c4cb

### 現在のSAMLプロバイダー
- **VPN Client**: arn:aws:iam::941377125831:saml-provider/aws-client-vpn
- **Self-Service**: arn:aws:iam::941377125831:saml-provider/aws-client-vpn-self-service
