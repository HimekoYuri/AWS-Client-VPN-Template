# ステップ3: SAML ApplicationへのグループAssign

## 📋 このステップでやること

Terraformで作成したVPN-UsersグループをSAML Applicationに割り当てます。

**所要時間**: 約5分

## 🎯 やること

1. VPN Client ApplicationにVPN-Usersグループを割り当て
2. VPN Self-Service ApplicationにVPN-Usersグループを割り当て

---

## 📝 パート1: VPN Client Applicationへの割り当て

### 1-1. AWS Management Consoleにアクセス

```
1. ブラウザで AWS Management Console を開く
   https://console.aws.amazon.com/

2. サービス検索で「IAM Identity Center」を検索

3. IAM Identity Center ダッシュボードを開く
```

### 1-2. VPN Client Applicationを開く

```
1. 左側メニューから「Applications」をクリック

2. アプリケーション一覧から「VPN Client」を探してクリック
```

### 1-3. グループ割り当て画面を開く

```
1. 「Assigned users and groups」タブをクリック

2. 「Assign users and groups」ボタンをクリック
```

### 1-4. VPN-Usersグループを選択

```
1. 「Groups」タブをクリック

2. グループ一覧から「VPN-Users」を探す
   ⚠️ これはTerraformで作成されたグループです
   
3. 「VPN-Users」の左側のチェックボックスをクリック

4. 「Assign users and groups」ボタンをクリック
```

**スクリーンショット参考**:
```
┌─────────────────────────────────────┐
│ Groups                              │
├─────────────────────────────────────┤
│ ☑ VPN-Users                         │
│   AWS Client VPN Users - Managed... │
│                                     │
│ ☐ Administrators                    │
│   ...                               │
└─────────────────────────────────────┘
```

### 1-5. 割り当て完了の確認

**成功メッセージ**:
```
Successfully assigned 1 group to VPN Client
```

**確認**:
```
1. 「Assigned users and groups」タブに戻る

2. 「VPN-Users」グループが表示されていることを確認

3. メンバー数が「1」と表示されていることを確認
```

---

## 📝 パート2: VPN Self-Service Applicationへの割り当て

### 2-1. VPN Self-Service Applicationを開く

```
1. 「Applications」に戻る

2. アプリケーション一覧から「VPN Client Self Service」を探してクリック
```

### 2-2. グループ割り当て画面を開く

```
1. 「Assigned users and groups」タブをクリック

2. 「Assign users and groups」ボタンをクリック
```

### 2-3. VPN-Usersグループを選択

```
1. 「Groups」タブをクリック

2. 「VPN-Users」を探してチェック

3. 「Assign users and groups」ボタンをクリック
```

### 2-4. 割り当て完了の確認

**成功メッセージ**:
```
Successfully assigned 1 group to VPN Client Self Service
```

**確認**:
```
1. 「Assigned users and groups」タブに戻る

2. 「VPN-Users」グループが表示されていることを確認
```

---

## 📝 パート3: 割り当て確認

### 3-1. 両方のアプリケーションを確認

```
1. 「Applications」に戻る

2. 「VPN Client」をクリック
   → 「Assigned users and groups」タブ
   → 「VPN-Users」が表示されていることを確認

3. 「Applications」に戻る

4. 「VPN Client Self Service」をクリック
   → 「Assigned users and groups」タブ
   → 「VPN-Users」が表示されていることを確認
```

### 3-2. ユーザーのアプリケーションアクセス確認

```
1. 左側メニューから「Users」をクリック

2. 「y-kalen」ユーザーをクリック

3. 「Applications」タブをクリック

4. 以下の2つのアプリケーションが表示されていることを確認:
   - VPN Client
   - VPN Client Self Service
```

**期待される表示**:
```
┌─────────────────────────────────────┐
│ Applications                        │
├─────────────────────────────────────┤
│ VPN Client                          │
│ Assigned via: VPN-Users             │
│                                     │
│ VPN Client Self Service             │
│ Assigned via: VPN-Users             │
└─────────────────────────────────────┘
```

---

## ✅ 完了確認

### チェックリスト

```
パート1: VPN Client Application
☑ VPN Client Applicationを開いた
☑ 「Assign users and groups」をクリック
☑ VPN-Usersグループを選択
☑ 割り当て完了
☑ 「Assigned users and groups」タブでVPN-Usersを確認

パート2: VPN Self-Service Application
☑ VPN Client Self Service Applicationを開いた
☑ 「Assign users and groups」をクリック
☑ VPN-Usersグループを選択
☑ 割り当て完了
☑ 「Assigned users and groups」タブでVPN-Usersを確認

パート3: 最終確認
☑ 両方のアプリケーションにVPN-Usersが割り当てられている
☑ y-kalenユーザーが両方のアプリケーションにアクセス可能
```

---

## 🔧 トラブルシューティング

### エラー1: VPN-Usersグループが表示されない

**原因**: グループの同期に時間がかかっている

**解決方法**:
```
1. 数分待ってから再度試す

2. ページをリロード

3. AWS CLIでグループを確認:
   aws identitystore list-groups \
     --identity-store-id d-9067dc092d \
     --filters AttributePath=DisplayName,AttributeValue=VPN-Users

4. グループが存在する場合、さらに数分待つ
```

### エラー2: 割り当てボタンがグレーアウト

**原因**: グループが選択されていない

**解決方法**:
```
1. 「Groups」タブが選択されているか確認

2. VPN-Usersの左側のチェックボックスをクリック

3. チェックマークが表示されることを確認

4. 「Assign users and groups」ボタンが青色になることを確認
```

### エラー3: エラーメッセージが表示される

**エラーメッセージ例**:
```
Error: Unable to assign group
```

**解決方法**:
```
1. IAM Identity Centerの権限を確認

2. ブラウザのキャッシュをクリア

3. 別のブラウザで試す

4. AWS Management Consoleからログアウトして再ログイン
```

---

## 📝 補足情報

### グループ割り当ての仕組み

```
VPN-Usersグループ
  ├─ y-kalen (User ID: b448d448-4061-7023-29b0-8901d5628601)
  │
  ├─ VPN Client Application
  │   └─ SAML認証でVPN接続
  │
  └─ VPN Client Self Service Application
      └─ VPN設定ファイルのダウンロード
```

### 今後のユーザー追加方法

新しいユーザーをVPNに追加する場合:

#### 方法1: Terraformで追加（推奨）

```bash
# terraform.tfvarsを編集
nano terraform/terraform.tfvars

# vpn_user_idsに新しいユーザーIDを追加
vpn_user_ids = [
  "b448d448-4061-7023-29b0-8901d5628601",  # y-kalen
  "new-user-id-here"                       # 新しいユーザー
]

# 適用
cd terraform
terraform apply
```

#### 方法2: AWS Management Consoleで追加

```
1. IAM Identity Center > Groups > VPN-Users

2. 「Add users to group」をクリック

3. 新しいユーザーを選択

4. 「Add users」をクリック
```

**⚠️ 注意**: 方法2で追加した場合、Terraformの管理外になります。

---

## 🎉 ステップ3完了！

SAML ApplicationへのグループAssignが完了しました。

次のステップ: [04-vpn-connection-test.md](04-vpn-connection-test.md)

---

**作成日**: 2025年1月26日  
**最終更新**: 2025年1月26日  
**バージョン**: 1.0.0
