# IAM Identity Center設定手順書

## 概要

本ドキュメントは、AWS Client VPNとIAM Identity Center（旧AWS SSO）を連携させるための設定手順を説明します。PC用VPNエンドポイントでSAML 2.0認証とMFA（多要素認証）を実現するために必要な設定を行います。

## 前提条件

- AWS IAM Identity Centerが有効化されていること
- AWS Management Consoleへのアクセス権限があること
- VPN接続を許可するユーザーとグループが作成されていること

## 設定手順

### 1. IAM Identity Centerへのアクセス

1. AWS Management Consoleにログイン
2. サービス検索で「IAM Identity Center」を検索
3. IAM Identity Centerダッシュボードを開く

### 2. SAML Application（VPN Client）の作成

#### 2.1 アプリケーションの追加

1. 左側メニューから「**Applications**」を選択
2. 「**Add application**」ボタンをクリック
3. 「**Add custom SAML 2.0 application**」を選択
4. 「**Next**」をクリック

#### 2.2 アプリケーション基本情報の設定

以下の情報を入力します：

| 項目 | 値 |
|------|-----|
| **Display name** | `VPN Client` |
| **Description** | `AWS Client VPN SAML Authentication` |
| **Application start URL** | （空欄のまま） |
| **Relay state** | （空欄のまま） |

「**Next**」をクリックして次へ進みます。

#### 2.3 SAML設定の構成

以下のSAML設定を入力します：

| 項目 | 値 |
|------|-----|
| **Application ACS URL** | `http://127.0.0.1:35001` |
| **Application SAML audience** | `urn:amazon:webservices:clientvpn` |

**重要:** これらの値は正確に入力してください。AWS Client VPNの認証に必須です。

#### 2.4 Attribute Mappingsの設定

以下のAttribute Mappingsを設定します：

| Application Attribute | IAM Identity Center Attribute | Format |
|----------------------|------------------------------|--------|
| `Subject` | `${user:email}` | `emailAddress` |
| `Name` | `${user:email}` | `unspecified` |
| `FirstName` | `${user:givenName}` | `unspecified` |
| `LastName` | `${user:familyName}` | `unspecified` |
| `memberOf` | `${user:groups}` | `unspecified` |

**設定手順:**

1. 「**Attribute mappings**」セクションで「**Add new attribute mapping**」をクリック
2. 上記の表に従って、各属性を追加
3. 特に`memberOf`属性は、グループベースの認可に必要です

**注意:** `memberOf`属性は、VPNエンドポイントの認可ルールでグループIDを使用する際に必須です。

#### 2.5 アプリケーションの保存

1. すべての設定を確認
2. 「**Submit**」をクリックしてアプリケーションを作成

### 3. SAML Application（VPN Self-Service Portal）の作成

VPNユーザーが自分でクライアント設定をダウンロードできるように、Self-Service Portal用のSAMLアプリケーションも作成します。

#### 3.1 アプリケーションの追加

1. 「**Applications**」から「**Add application**」をクリック
2. 「**Add custom SAML 2.0 application**」を選択
3. 「**Next**」をクリック

#### 3.2 アプリケーション基本情報の設定

| 項目 | 値 |
|------|-----|
| **Display name** | `VPN Client Self Service` |
| **Description** | `AWS Client VPN Self-Service Portal` |
| **Application start URL** | `https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml` |

#### 3.3 SAML設定の構成

| 項目 | 値 |
|------|-----|
| **Application ACS URL** | `https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml` |
| **Application SAML audience** | `urn:amazon:webservices:clientvpn` |

#### 3.4 Attribute Mappingsの設定

VPN Client用と同じAttribute Mappingsを設定します（前述の表を参照）。

#### 3.5 アプリケーションの保存

「**Submit**」をクリックしてアプリケーションを作成します。

### 4. ユーザーとグループの割り当て

#### 4.1 グループの作成（未作成の場合）

1. 左側メニューから「**Groups**」を選択
2. 「**Create group**」をクリック
3. グループ名を入力（例: `VPN-Users`）
4. グループの説明を入力
5. 「**Create group**」をクリック

#### 4.2 ユーザーのグループへの追加

1. 作成したグループを選択
2. 「**Add users**」をクリック
3. VPN接続を許可するユーザーを選択
4. 「**Add users**」をクリック

#### 4.3 アプリケーションへのグループ割り当て

**VPN Clientアプリケーション:**

1. 「**Applications**」から「**VPN Client**」を選択
2. 「**Assign users and groups**」タブを選択
3. 「**Assign users and groups**」ボタンをクリック
4. 「**Groups**」タブを選択
5. 作成したVPNグループ（例: `VPN-Users`）を選択
6. 「**Assign users and groups**」をクリック

**VPN Client Self Serviceアプリケーション:**

同様の手順で、Self-Serviceアプリケーションにもグループを割り当てます。

### 5. SAMLメタデータのダウンロード

Terraformで使用するため、各アプリケーションのSAMLメタデータをダウンロードします。

#### 5.1 VPN Clientメタデータのダウンロード

1. 「**Applications**」から「**VPN Client**」を選択
2. 「**Actions**」ドロップダウンをクリック
3. 「**Edit attribute mappings**」を選択
4. ページ下部の「**IAM Identity Center metadata**」セクションを確認
5. 「**IAM Identity Center SAML metadata file**」のリンクをクリック
6. XMLファイルをダウンロード
7. ファイル名を`vpn-client-metadata.xml`に変更
8. プロジェクトの`metadata/`ディレクトリに保存

**保存先:** `metadata/vpn-client-metadata.xml`

#### 5.2 VPN Self-Serviceメタデータのダウンロード

1. 「**Applications**」から「**VPN Client Self Service**」を選択
2. 同様の手順でメタデータをダウンロード
3. ファイル名を`vpn-self-service-metadata.xml`に変更
4. プロジェクトの`metadata/`ディレクトリに保存

**保存先:** `metadata/vpn-self-service-metadata.xml`

### 6. グループIDの取得

Terraformの認可ルール設定で使用するため、グループIDを取得します。

#### 6.1 グループIDの確認

1. 「**Groups**」から作成したVPNグループを選択
2. グループの詳細ページで「**Group ID**」を確認
3. Group IDをコピー（形式: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`）

#### 6.2 Terraform変数への設定

取得したGroup IDを`terraform.tfvars`ファイルに設定します：

```hcl
iic_vpn_group_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

**セキュリティ注意:** `terraform.tfvars`ファイルは`.gitignore`に含まれており、Gitにコミットされません。

### 7. MFA（多要素認証）の有効化

VPN接続時にMFAを要求するため、ユーザーにMFAデバイスの登録を促します。

#### 7.1 ユーザーへのMFA登録案内

1. ユーザーにIAM Identity Centerのユーザーポータルへのアクセスを案内
2. ユーザーポータルURL: `https://[your-identity-center-domain].awsapps.com/start`
3. ユーザーは以下の手順でMFAデバイスを登録：
   - ユーザーポータルにログイン
   - 右上のユーザー名をクリック
   - 「**MFA devices**」を選択
   - 「**Register MFA device**」をクリック
   - 認証アプリ（Google Authenticator、Microsoft Authenticatorなど）でQRコードをスキャン
   - 確認コードを入力して登録完了

#### 7.2 MFA必須化の設定（オプション）

組織のセキュリティポリシーに応じて、MFAを必須化できます：

1. 「**Settings**」を選択
2. 「**Authentication**」タブを選択
3. 「**Multi-factor authentication**」セクションで設定を変更
4. 「**Require MFA**」を選択
5. 「**Save changes**」をクリック

## 設定確認

### 1. SAMLメタデータファイルの確認

以下のファイルが存在することを確認します：

```
metadata/
├── vpn-client-metadata.xml
└── vpn-self-service-metadata.xml
```

### 2. Terraform変数の確認

`terraform.tfvars`ファイルに以下の変数が設定されていることを確認します：

```hcl
iic_vpn_group_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### 3. ユーザーとグループの確認

- VPN用グループが作成されていること
- グループに適切なユーザーが追加されていること
- 両方のSAMLアプリケーションにグループが割り当てられていること

## トラブルシューティング

### SAMLメタデータが見つからない

**症状:** メタデータダウンロードリンクが表示されない

**解決方法:**
1. アプリケーションの設定を保存したことを確認
2. ページをリロード
3. 「**Edit attribute mappings**」ページで再度確認

### グループIDが見つからない

**症状:** グループの詳細ページにGroup IDが表示されない

**解決方法:**
1. AWS CLIを使用してグループIDを取得：
   ```bash
   aws identitystore list-groups \
     --identity-store-id d-xxxxxxxxxx \
     --filters AttributePath=DisplayName,AttributeValue=VPN-Users
   ```
2. Identity Store IDは、IAM Identity Centerの設定ページで確認できます

### Attribute Mappingsが正しく設定されない

**症状:** VPN接続時に認証エラーが発生

**解決方法:**
1. Attribute Mappingsを再確認
2. 特に`Subject`と`memberOf`が正しく設定されているか確認
3. Formatが正しいか確認（`Subject`は`emailAddress`、他は`unspecified`）

## セキュリティ上の注意事項

### SAMLメタデータの保護

- SAMLメタデータファイルは機密情報を含みます
- `.gitignore`に`metadata/*.xml`が含まれていることを確認
- メタデータファイルをGitにコミットしないでください

### グループIDの保護

- Group IDは認可制御に使用される重要な情報です
- `terraform.tfvars`ファイルをGitにコミットしないでください
- 必要に応じて、AWS Secrets ManagerやParameter Storeの使用を検討してください

### MFAの推奨

- すべてのVPNユーザーにMFAの登録を強く推奨します
- 組織のセキュリティポリシーに応じて、MFAを必須化してください

## 次のステップ

IAM Identity Centerの設定が完了したら、以下の手順に進みます：

1. Terraformで`terraform plan`を実行し、設定を確認
2. `terraform apply`を実行し、VPNエンドポイントをデプロイ
3. VPN接続テストを実施（[VPN接続手順書](vpn-connection-pc.md)を参照）

## 参考資料

- [AWS IAM Identity Center User Guide](https://docs.aws.amazon.com/singlesignon/latest/userguide/)
- [Authenticate AWS Client VPN users with AWS IAM Identity Center](https://aws.amazon.com/blogs/security/authenticate-aws-client-vpn-users-with-aws-single-sign-on/)
- [AWS Client VPN Administrator Guide - SAML Authentication](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/client-authentication.html#federated-authentication)

## 更新履歴

| 日付 | 変更内容 | 担当者 |
|------|---------|--------|
| 2024-XX-XX | 初版作成 | - |

---

**注意:** 本ドキュメントの手順は、AWS Management Consoleの最新バージョンに基づいています。UIが変更される可能性がありますので、最新の公式ドキュメントも併せてご確認ください。
