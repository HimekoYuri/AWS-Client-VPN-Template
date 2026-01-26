# IAM Identity Center SAML アプリケーション設定手順

## 前提条件
- IAM Identity Centerが有効化されていること
- VPN-Usersグループが作成されていること
- vpn-testユーザーがVPN-Usersグループに所属していること

## 1. VPN-Client アプリケーションの作成

### 1-1. アプリケーション作成
1. AWSコンソールで **IAM Identity Center** を開く
2. 左メニューから **Applications** を選択
3. **Add application** をクリック
4. **Add custom SAML 2.0 application** を選択
5. **Next** をクリック

### 1-2. アプリケーション詳細設定
- **Display name**: `VPN-Client`
- **Description**: `AWS Client VPN SAML Authentication`
- **Application start URL**: (空欄)
- **Relay state**: (空欄)
- **Session duration**: `8 hours`

### 1-3. SAML設定
- **Application ACS URL**: `http://127.0.0.1:35001`
- **Application SAML audience**: `urn:amazon:webservices:clientvpn`

### 1-4. Attribute mappings
以下のマッピングを追加:

| User attribute in IAM Identity Center | Maps to this string value or user attribute in the application | Format |
|---------------------------------------|----------------------------------------------------------------|--------|
| `${user:email}` | Subject | emailAddress |
| `${user:email}` | Name | unspecified |
| `${user:givenName}` | FirstName | unspecified |
| `${user:familyName}` | LastName | unspecified |
| `${user:groups}` | memberOf | unspecified |

### 1-5. アプリケーション作成完了
- **Submit** をクリック

### 1-6. メタデータのダウンロード
1. 作成した **VPN-Client** アプリケーションを開く
2. **Actions** > **Edit configuration** をクリック
3. **IAM Identity Center metadata** セクションで **Download metadata file** をクリック
4. ダウンロードしたファイルを以下に保存:
   ```
   /mnt/d/CloudDrive/Google/Client-VPN-test/metadata/vpn-client-metadata.xml
   ```

### 1-7. アクセス権限の付与
1. **VPN-Client** アプリケーションの **Assigned users and groups** タブを開く
2. **Assign users and groups** をクリック
3. **Groups** タブで **VPN-Users** を選択
4. **Assign users and groups** をクリック

## 2. VPN-Self-Service アプリケーションの作成

### 2-1. アプリケーション作成
1. **Applications** ページで **Add application** をクリック
2. **Add custom SAML 2.0 application** を選択
3. **Next** をクリック

### 2-2. アプリケーション詳細設定
- **Display name**: `VPN-Self-Service`
- **Description**: `AWS Client VPN Self-Service Portal`
- **Application start URL**: (空欄)
- **Relay state**: (空欄)
- **Session duration**: `8 hours`

### 2-3. SAML設定
- **Application ACS URL**: `https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml`
- **Application SAML audience**: `urn:amazon:webservices:clientvpn`

### 2-4. Attribute mappings
以下のマッピングを追加:

| User attribute in IAM Identity Center | Maps to this string value or user attribute in the application | Format |
|---------------------------------------|----------------------------------------------------------------|--------|
| `${user:email}` | Subject | emailAddress |
| `${user:email}` | Name | unspecified |

### 2-5. アプリケーション作成完了
- **Submit** をクリック

### 2-6. メタデータのダウンロード
1. 作成した **VPN-Self-Service** アプリケーションを開く
2. **Actions** > **Edit configuration** をクリック
3. **IAM Identity Center metadata** セクションで **Download metadata file** をクリック
4. ダウンロードしたファイルを以下に保存:
   ```
   /mnt/d/CloudDrive/Google/Client-VPN-test/metadata/vpn-self-service-metadata.xml
   ```

### 2-7. アクセス権限の付与
1. **VPN-Self-Service** アプリケーションの **Assigned users and groups** タブを開く
2. **Assign users and groups** をクリック
3. **Groups** タブで **VPN-Users** を選択
4. **Assign users and groups** をクリック

## 3. メタデータファイルの確認

ダウンロードしたメタデータファイルが正しく配置されているか確認:

```bash
ls -la /mnt/d/CloudDrive/Google/Client-VPN-test/metadata/
```

以下の2ファイルが存在すること:
- `vpn-client-metadata.xml`
- `vpn-self-service-metadata.xml`

## 4. Terraform適用

メタデータファイルが配置できたら、VPNエンドポイントを作成:

```bash
cd /mnt/d/CloudDrive/Google/Client-VPN-test/terraform

# 無効化したファイルを有効化
mv iam_saml.tf.disabled iam_saml.tf
mv client_vpn_pc.tf.disabled client_vpn_pc.tf
mv client_vpn_mobile.tf.disabled client_vpn_mobile.tf

# 認証情報を設定
eval $(aws configure export-credentials --format env)
export AWS_DEFAULT_REGION=ap-northeast-1

# Plan実行
terraform plan -out=tfplan

# Apply実行
terraform apply tfplan
```

## トラブルシューティング

### メタデータファイルが見つからない
- ファイルパスが正しいか確認
- ファイル名が正確か確認（拡張子含む）

### SAMLメタデータのパースエラー
- ダウンロードしたメタデータファイルが破損していないか確認
- ブラウザで直接開いて、XMLとして正しいか確認

### アクセス権限エラー
- VPN-Usersグループが両方のアプリケーションに割り当てられているか確認
- vpn-testユーザーがVPN-Usersグループのメンバーか確認

## 参考情報

### IAM Identity Centerコンソール
```
https://ap-northeast-1.console.aws.amazon.com/singlesignon/home?region=ap-northeast-1
```

### Identity Store ID
```
d-9567adbcf1
```

### VPN-Users Group ID
```
1794ca98-90d1-70c9-40d1-dbd229b42262
```

### vpn-test User ID
```
7784aad8-2051-70b9-491f-89cf9e87c4cb
```
