# デプロイメントガイド

## 構築済み環境情報

### 実行日時
2026年1月26日

### AWSアカウント
- アカウントID: 941377125831
- リージョン: ap-northeast-1 (東京)

## 構築されたリソース

### ネットワークインフラ
- **VPC**: vpc-0e90cfcb472e466b7 (192.168.0.0/16)
- **パブリックサブネット**: 
  - subnet-0436b4f582ee1f260 (ap-northeast-1a)
  - subnet-056da646e9d2d7a1a (ap-northeast-1c)
- **プライベートサブネット**: 
  - subnet-0730db07f1bcd55da (ap-northeast-1a)
  - subnet-055aeeb0c09035a90 (ap-northeast-1c)
- **インターネットゲートウェイ**: igw-07b56ee9e06b5d88f
- **NATゲートウェイ**: nat-0fb102eef663f8e1b
- **NAT Gateway EIP**: 3.113.217.140
- **セキュリティグループ**: sg-02a67926fbc4476a4

### Client VPNエンドポイント

#### モバイル用VPN (証明書認証)
- **エンドポイントID**: cvpn-endpoint-0d3f4f2c3722e6c20
- **DNS名**: *.cvpn-endpoint-0d3f4f2c3722e6c20.prod.clientvpn.ap-northeast-1.amazonaws.com
- **クライアントCIDR**: 172.17.0.0/22
- **認証方式**: 相互TLS証明書認証
- **Split-tunnel**: 無効 (全トラフィックVPN経由)
- **ステータス**: available ✅

### 証明書 (ACM)
- **サーバー証明書**: arn:aws:acm:ap-northeast-1:941377125831:certificate/37714a19-9c66-4afc-9c95-7a0a900b983c
  - CN: server.vpn.example.com
  - 有効期限: 2028年4月29日
- **クライアント証明書**: arn:aws:acm:ap-northeast-1:941377125831:certificate/b9c80c02-f7f4-4eb5-8e0e-f2802d17dc12

### IAM Identity Center
- **Identity Store ID**: d-9567adbcf1
- **SSO Instance ARN**: arn:aws:sso:::instance/ssoins-775851192c170650
- **VPN-Usersグループ**: 1794ca98-90d1-70c9-40d1-dbd229b42262
- **vpn-testユーザー**: 7784aad8-2051-70b9-491f-89cf9e87c4cb

### ログ & 監視
- **モバイルVPN Log Group**: /aws/clientvpn/mobile
- **CloudTrail**: client-vpn-trail
- **S3バケット**: client-vpn-cloudtrail-logs-941377125831

## VPN接続手順

### モバイルVPN接続

1. **設定ファイルの準備**
   ```bash
   # 設定ファイルは以下に配置済み
   mobile-vpn-config-v2-complete.ovpn
   ```

2. **OpenVPN Connectのインストール**
   - iOS: App Storeから「OpenVPN Connect」をインストール
   - Android: Google Playから「OpenVPN Connect」をインストール

3. **設定ファイルのインポート**
   - 設定ファイルをスマホに転送
   - OpenVPN Connectアプリで「Import Profile」
   - ファイルを選択してインポート

4. **VPN接続**
   - 接続ボタンをタップ
   - 証明書で自動認証
   - 接続完了! ✅

## 接続テスト

### 接続確認
```bash
# VPN接続後、以下を確認
ping 8.8.8.8          # インターネット接続確認
nslookup google.com   # DNS名前解決確認
curl ifconfig.me      # 送信元IP確認 (NAT Gateway IP: 3.113.217.140)
```

### ログ確認
```bash
# VPN接続ログの確認
aws logs tail /aws/clientvpn/mobile --follow --region ap-northeast-1

# CloudTrailログの確認
aws s3 ls s3://client-vpn-cloudtrail-logs-941377125831/ --recursive
```

## メンテナンス

### 証明書の更新

証明書の有効期限は2028年4月29日です。更新手順:

```bash
cd easy-rsa/easyrsa3

# 新しいサーバー証明書の生成
./easyrsa build-server-full server.vpn.example.com nopass

# 新しいクライアント証明書の生成
./easyrsa build-client-full client2.vpn.example.com nopass

# Terraformで証明書を更新
cd ../../terraform
terraform apply
```

### ユーザーの追加

```bash
# IAM Identity Centerで新しいユーザーを作成
aws identitystore create-user \
  --identity-store-id d-9567adbcf1 \
  --user-name "new-user" \
  --display-name "New User" \
  --name GivenName=New,FamilyName=User \
  --emails Value=new-user@example.com,Type=work,Primary=true

# VPN-Usersグループに追加
aws identitystore create-group-membership \
  --identity-store-id d-9567adbcf1 \
  --group-id 1794ca98-90d1-70c9-40d1-dbd229b42262 \
  --member-id UserId=<new-user-id>
```

### リソースの削除

```bash
cd terraform
terraform destroy
```

**注意**: 削除前にVPN接続を全て切断してください。

## セキュリティチェックリスト

- [x] S3バケットのパブリックアクセスブロック有効
- [x] S3バケットのバージョニング有効
- [x] S3バケットのSSE-S3暗号化有効
- [x] CloudTrail監査ログ記録
- [x] CloudWatch Logsアクセスログ記録
- [x] セキュリティグループで最小権限アクセス
- [x] プライベートサブネットにVPNエンドポイント配置
- [x] 証明書による相互TLS認証
- [ ] 証明書の有効期限管理 (2028年4月まで)
- [ ] VPN接続ログの定期的な確認
- [ ] IAM Identity Centerユーザーの定期的なレビュー

## コスト最適化

### 現在の月額コスト (概算)
- Client VPNエンドポイント: $73
- NAT Gateway: $45 + データ転送料
- CloudWatch Logs: $5-10 (使用量による)
- S3 (CloudTrail): $1-5 (使用量による)

**合計**: 約 $124-133/月

### コスト削減案
- 使用しない時間帯はVPNエンドポイントを削除
- CloudWatch Logsの保持期間を短縮
- 不要なログを削除

## サポート

問題が発生した場合は、[TROUBLESHOOTING.md](TROUBLESHOOTING.md)を参照してください。
