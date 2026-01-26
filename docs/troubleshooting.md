# トラブルシューティングガイド

## VPN接続の問題

### 接続できない

#### 症状
OpenVPN Connectで接続ボタンを押しても接続できない

#### 確認事項
1. **証明書の有効性**
   ```bash
   openssl x509 -in certs/client1.vpn.example.com.crt -noout -dates
   ```
   有効期限を確認してください。

2. **VPNエンドポイントの状態**
   ```bash
   aws ec2 describe-client-vpn-endpoints \
     --client-vpn-endpoint-ids cvpn-endpoint-0d3f4f2c3722e6c20 \
     --region ap-northeast-1 \
     --query 'ClientVpnEndpoints[0].Status.Code'
   ```
   `available`であることを確認してください。

3. **設定ファイルの確認**
   - 証明書と秘密鍵が正しく含まれているか確認
   - ファイルが破損していないか確認

#### 解決方法
```bash
# 新しい設定ファイルを生成
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id cvpn-endpoint-0d3f4f2c3722e6c20 \
  --region ap-northeast-1 \
  --output text > mobile-vpn-config-new.ovpn

# 証明書を追加
cat >> mobile-vpn-config-new.ovpn << EOF

<cert>
$(cat certs/client1.vpn.example.com.crt)
</cert>

<key>
$(cat certs/client1.vpn.example.com.key)
</key>
EOF
```

### 接続後にインターネットに接続できない

#### 症状
VPN接続は成功するが、Webサイトにアクセスできない、名前解決ができない

#### 確認事項
1. **Split-tunnel設定**
   ```bash
   aws ec2 describe-client-vpn-endpoints \
     --client-vpn-endpoint-ids cvpn-endpoint-0d3f4f2c3722e6c20 \
     --region ap-northeast-1 \
     --query 'ClientVpnEndpoints[0].SplitTunnel'
   ```
   `false`であることを確認してください。

2. **ルート設定**
   ```bash
   aws ec2 describe-client-vpn-routes \
     --client-vpn-endpoint-id cvpn-endpoint-0d3f4f2c3722e6c20 \
     --region ap-northeast-1
   ```
   `0.0.0.0/0`へのルートが存在することを確認してください。

3. **NATゲートウェイの状態**
   ```bash
   aws ec2 describe-nat-gateways \
     --nat-gateway-ids nat-0fb102eef663f8e1b \
     --region ap-northeast-1 \
     --query 'NatGateways[0].State'
   ```
   `available`であることを確認してください。

#### 解決方法
```bash
# Split-tunnelを無効化
cd terraform
terraform apply -target=aws_ec2_client_vpn_endpoint.mobile -auto-approve

# 新しい設定ファイルをダウンロード
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id cvpn-endpoint-0d3f4f2c3722e6c20 \
  --region ap-northeast-1 \
  --output text > mobile-vpn-config-fixed.ovpn
```

### 認証エラー

#### 症状
`Authentication failed`エラーが表示される

#### 確認事項
1. **証明書の一致**
   - 設定ファイルに含まれる証明書が正しいか確認
   - サーバー証明書とクライアント証明書が同じCAで署名されているか確認

2. **ACM証明書の状態**
   ```bash
   aws acm describe-certificate \
     --certificate-arn arn:aws:acm:ap-northeast-1:941377125831:certificate/b9c80c02-f7f4-4eb5-8e0e-f2802d17dc12 \
     --region ap-northeast-1 \
     --query 'Certificate.Status'
   ```
   `ISSUED`であることを確認してください。

#### 解決方法
証明書を再生成して、ACMに再インポートしてください。

## Terraform関連の問題

### terraform apply失敗

#### 症状
`terraform apply`実行時にエラーが発生する

#### よくあるエラー

**1. 認証エラー**
```
Error: No valid credential sources found
```

**解決方法**:
```bash
aws login
eval $(aws configure export-credentials --format env)
export AWS_DEFAULT_REGION=ap-northeast-1
```

**2. リソースの競合**
```
Error: resource already exists
```

**解決方法**:
```bash
# 既存リソースをインポート
terraform import <resource_type>.<resource_name> <resource_id>
```

**3. 証明書ファイルが見つからない**
```
Error: no such file or directory
```

**解決方法**:
証明書を生成してから再実行してください。

### terraform destroy失敗

#### 症状
リソースの削除に失敗する

#### 解決方法
```bash
# VPN接続を全て切断してから実行
terraform destroy

# 特定のリソースだけ削除
terraform destroy -target=<resource>
```

## AWS CLI関連の問題

### セッション期限切れ

#### 症状
```
Your session has expired. Please reauthenticate using 'aws login'.
```

#### 解決方法
```bash
aws login
```

### リージョンエラー

#### 症状
```
Error: region not specified
```

#### 解決方法
```bash
export AWS_DEFAULT_REGION=ap-northeast-1
# または
aws configure set region ap-northeast-1
```

## ログの確認方法

### VPN接続ログ

```bash
# リアルタイムでログを確認
aws logs tail /aws/clientvpn/mobile --follow --region ap-northeast-1

# 特定期間のログを確認
aws logs filter-log-events \
  --log-group-name /aws/clientvpn/mobile \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --region ap-northeast-1
```

### CloudTrailログ

```bash
# S3バケットのログを確認
aws s3 ls s3://client-vpn-cloudtrail-logs-941377125831/ --recursive

# 特定のログをダウンロード
aws s3 cp s3://client-vpn-cloudtrail-logs-941377125831/<path> ./
```

## パフォーマンスの問題

### 接続が遅い

#### 確認事項
1. NATゲートウェイのメトリクスを確認
2. VPNエンドポイントのメトリクスを確認
3. クライアント側のネットワーク状況を確認

#### 解決方法
- NATゲートウェイを複数配置
- VPNエンドポイントを複数のAZに配置
- クライアント側のネットワークを改善

### 頻繁に切断される

#### 確認事項
1. セッションタイムアウト設定を確認
2. クライアント側のネットワーク安定性を確認

#### 解決方法
```bash
# セッションタイムアウトを延長
# terraform/client_vpn_mobile.tfで設定
session_timeout_hours = 24
```

## よくある質問

### Q: 複数のクライアント証明書を発行できますか?
A: はい、easy-rsaで複数の証明書を生成できます。
```bash
./easyrsa build-client-full client2.vpn.example.com nopass
./easyrsa build-client-full client3.vpn.example.com nopass
```

### Q: 証明書を無効化するには?
A: easy-rsaで証明書を失効させます。
```bash
./easyrsa revoke client1.vpn.example.com
./easyrsa gen-crl
```

### Q: VPNエンドポイントを一時停止できますか?
A: いいえ、VPNエンドポイントは削除するしかありません。コスト削減のため、使用しない場合は削除してください。

### Q: 送信元IPアドレスは固定ですか?
A: はい、NAT Gateway EIP (3.113.217.140) が送信元IPとして使用されます。

## サポート連絡先

技術的な問題が解決しない場合は、以下を確認してください:
- [AWS Client VPN ドキュメント](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/)
- [Terraform AWS Provider ドキュメント](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 緊急時の対応

### VPNが完全に動作しない場合

1. **一時的な対処**
   ```bash
   # VPNエンドポイントを削除
   terraform destroy -target=aws_ec2_client_vpn_endpoint.mobile
   
   # 再作成
   terraform apply -target=aws_ec2_client_vpn_endpoint.mobile
   ```

2. **完全な再構築**
   ```bash
   # 全リソースを削除
   terraform destroy
   
   # 再構築
   terraform apply
   ```

**注意**: 再構築すると、新しいVPNエンドポイントIDが発行されるため、設定ファイルを再配布する必要があります。
