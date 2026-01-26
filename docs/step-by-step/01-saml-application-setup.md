# ステップ1: SAML Application作成

## 📋 このステップでやること

IAM Identity CenterでSAML Applicationを2個作成し、SAMLメタデータをダウンロードします。

**所要時間**: 約15分

## 🎯 作成するもの

1. **VPN Client Application** - VPN認証用
2. **VPN Self-Service Application** - 設定ファイルダウンロード用

---

## 📝 パート1: VPN Client Application作成

### 1-1. AWS Management Consoleにアクセス

```
1. ブラウザで AWS Management Console を開く
   https://console.aws.amazon.com/

2. サービス検索で「IAM Identity Center」を検索

3. IAM Identity Center ダッシュボードを開く
```

### 1-2. アプリケーション追加画面を開く

```
1. 左側メニューから「Applications」をクリック

2. 「Add application」ボタンをクリック

3. 「Add custom SAML 2.0 application」を選択

4. 「Next」をクリック
```

### 1-3. アプリケーション基本情報の入力

```
Display name: VPN Client
Description: AWS Client VPN SAML Authentication
Application start URL: （空欄のまま）
Relay state: （空欄のまま）
```

**スクリーンショット参考**:
```
┌─────────────────────────────────────┐
│ Display name *                      │
│ VPN Client                          │
├─────────────────────────────────────┤
│ Description                         │
│ AWS Client VPN SAML Authentication  │
├─────────────────────────────────────┤
│ Application start URL               │
│ （空欄）                            │
└─────────────────────────────────────┘
```

「Next」をクリック

### 1-4. SAML設定の入力

```
Application ACS URL: http://127.0.0.1:35001
Application SAML audience: urn:amazon:webservices:clientvpn
```

**⚠️ 重要**: この値は正確にコピーしてください。1文字でも間違えると認証が失敗します。

**コピー用**:
```
http://127.0.0.1:35001
urn:amazon:webservices:clientvpn
```

### 1-5. Attribute Mappingsの設定

「Add new attribute mapping」を5回クリックして、以下を入力します：

#### Mapping 1
```
Application attribute: Subject
IAM Identity Center attribute: ${user:email}
Format: emailAddress
```

#### Mapping 2
```
Application attribute: Name
IAM Identity Center attribute: ${user:email}
Format: unspecified
```

#### Mapping 3
```
Application attribute: FirstName
IAM Identity Center attribute: ${user:givenName}
Format: unspecified
```

#### Mapping 4
```
Application attribute: LastName
IAM Identity Center attribute: ${user:familyName}
Format: unspecified
```

#### Mapping 5
```
Application attribute: memberOf
IAM Identity Center attribute: ${user:groups}
Format: unspecified
```

**⚠️ 重要**: `memberOf`属性は必須です。これがないとグループベースの認可が機能しません。

**設定完了後**:
```
「Submit」をクリック
```

### 1-6. SAMLメタデータのダウンロード

```
1. 作成した「VPN Client」アプリケーションをクリック

2. 「Actions」ドロップダウンをクリック

3. 「Edit attribute mappings」を選択

4. ページを下にスクロール

5. 「IAM Identity Center metadata」セクションを見つける

6. 「IAM Identity Center SAML metadata file」のリンクをクリック

7. XMLファイルがダウンロードされる
```

### 1-7. メタデータファイルの保存

#### Windowsの場合

```powershell
# ダウンロードしたファイルを確認
dir C:\Users\y-kalen\Downloads\

# ファイル名を変更して移動
cd D:\CloudDrive\Google\Client-VPN-test\metadata
copy C:\Users\y-kalen\Downloads\<ダウンロードしたファイル名>.xml vpn-client-metadata.xml
```

#### Linux/WSLの場合

```bash
# ダウンロードしたファイルを確認
ls -la ~/Downloads/

# ファイル名を変更して移動
cd /mnt/d/CloudDrive/Google/Client-VPN-test/metadata
cp ~/Downloads/<ダウンロードしたファイル名>.xml vpn-client-metadata.xml
```

**保存先**: `metadata/vpn-client-metadata.xml`

---

## 📝 パート2: VPN Self-Service Application作成

### 2-1. アプリケーション追加画面を開く

```
1. 「Applications」に戻る

2. 「Add application」ボタンをクリック

3. 「Add custom SAML 2.0 application」を選択

4. 「Next」をクリック
```

### 2-2. アプリケーション基本情報の入力

```
Display name: VPN Client Self Service
Description: AWS Client VPN Self-Service Portal
Application start URL: https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml
Relay state: （空欄のまま）
```

**コピー用**:
```
https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml
```

「Next」をクリック

### 2-3. SAML設定の入力

```
Application ACS URL: https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml
Application SAML audience: urn:amazon:webservices:clientvpn
```

**コピー用**:
```
https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml
urn:amazon:webservices:clientvpn
```

### 2-4. Attribute Mappingsの設定

**パート1と同じAttribute Mappingsを設定**します。

5つのマッピングを追加:
1. Subject → ${user:email} (emailAddress)
2. Name → ${user:email} (unspecified)
3. FirstName → ${user:givenName} (unspecified)
4. LastName → ${user:familyName} (unspecified)
5. memberOf → ${user:groups} (unspecified)

「Submit」をクリック

### 2-5. SAMLメタデータのダウンロード

```
1. 「VPN Client Self Service」アプリケーションをクリック

2. 「Actions」> 「Edit attribute mappings」

3. 「IAM Identity Center SAML metadata file」をダウンロード
```

### 2-6. メタデータファイルの保存

#### Windowsの場合

```powershell
cd D:\CloudDrive\Google\Client-VPN-test\metadata
copy C:\Users\y-kalen\Downloads\<ダウンロードしたファイル名>.xml vpn-self-service-metadata.xml
```

#### Linux/WSLの場合

```bash
cd /mnt/d/CloudDrive/Google/Client-VPN-test/metadata
cp ~/Downloads/<ダウンロードしたファイル名>.xml vpn-self-service-metadata.xml
```

**保存先**: `metadata/vpn-self-service-metadata.xml`

---

## ✅ 完了確認

### メタデータファイルの確認

#### Windowsの場合

```powershell
cd D:\CloudDrive\Google\Client-VPN-test
dir metadata\

# 期待される出力:
# vpn-client-metadata.xml
# vpn-self-service-metadata.xml
```

#### Linux/WSLの場合

```bash
cd /mnt/d/CloudDrive/Google/Client-VPN-test
ls -la metadata/

# 期待される出力:
# vpn-client-metadata.xml
# vpn-self-service-metadata.xml
```

### ファイル内容の確認

```bash
# XMLファイルの先頭を確認
head -n 5 metadata/vpn-client-metadata.xml

# 期待される出力:
# <?xml version="1.0" encoding="UTF-8"?>
# <EntityDescriptor ...>
```

---

## 📋 チェックリスト

```
パート1: VPN Client Application
☑ アプリケーション作成完了
☑ Display name: VPN Client
☑ Application ACS URL: http://127.0.0.1:35001
☑ Attribute Mappings 5個設定完了
☑ SAMLメタデータダウンロード完了
☑ vpn-client-metadata.xml 保存完了

パート2: VPN Self-Service Application
☑ アプリケーション作成完了
☑ Display name: VPN Client Self Service
☑ Application ACS URL: https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml
☑ Attribute Mappings 5個設定完了
☑ SAMLメタデータダウンロード完了
☑ vpn-self-service-metadata.xml 保存完了

最終確認
☑ metadata/フォルダに2個のXMLファイルが存在
☑ ファイルサイズが0バイトでない
```

---

## 🔧 トラブルシューティング

### エラー1: メタデータダウンロードリンクが表示されない

**原因**: アプリケーションの設定が保存されていない

**解決方法**:
1. アプリケーションの設定を再確認
2. 「Submit」をクリックして保存
3. ページをリロード
4. 「Actions」> 「Edit attribute mappings」を再度開く

### エラー2: XMLファイルが開けない

**原因**: ダウンロードが不完全

**解決方法**:
1. ブラウザのダウンロード履歴を確認
2. ファイルサイズが0バイトでないか確認
3. 再度ダウンロード

### エラー3: ファイルが見つからない

**原因**: 保存先が間違っている

**解決方法**:
```bash
# 正しい保存先を確認
cd /mnt/d/CloudDrive/Google/Client-VPN-test
pwd

# metadata/フォルダが存在するか確認
ls -la | grep metadata

# 存在しない場合は作成
mkdir -p metadata
```

---

## 🎉 ステップ1完了！

SAML Applicationの作成とメタデータのダウンロードが完了しました。

次のステップ: [02-terraform-deployment.md](02-terraform-deployment.md)

---

**作成日**: 2025年1月26日  
**最終更新**: 2025年1月26日  
**バージョン**: 1.0.0
