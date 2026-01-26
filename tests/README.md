# テストディレクトリ

このディレクトリには、AWS Client VPNインフラストラクチャのテストコードを格納します。

## ディレクトリ構造

```
tests/
├── property/           # プロパティベーステスト（今後追加予定）
│   ├── conftest.py    # 共通設定
│   ├── test_terraform_security.py
│   └── test_aws_credentials_security.py
├── integration/        # 統合テスト
│   ├── conftest.py    # boto3クライアント設定
│   └── test_network_infrastructure.py  # ネットワーク構成検証テスト（Task 2.5）
└── requirements.txt    # テスト依存パッケージ
```


## セットアップ

### 1. 依存パッケージのインストール

```bash
pip install -r tests/requirements.txt
```

### 2. AWS認証情報の設定

テストを実行する前に、AWS CLIで認証を行ってください：

```bash
aws sso login --profile your-profile
```

または、環境変数を設定：

```bash
export AWS_PROFILE=your-profile
export AWS_REGION=ap-northeast-1
```

## テストの種類

### プロパティベーステスト
- **目的**: 普遍的なセキュリティプロパティを検証
- **フレームワーク**: Python + Hypothesis
- **実行回数**: 最低100回の反復実行

### 統合テスト
- **目的**: 具体的なシナリオ、エッジケース、エラー条件を検証
- **フレームワーク**: Python + pytest + boto3

#### test_network_infrastructure.py (Task 2.5)

ネットワーク構成の検証テスト（Requirements 5.1, 5.2, 5.4, 5.5）

**TestVPCConfiguration**
- VPCが作成されていることを検証
- VPCが正しいCIDRブロック（192.168.0.0/16）で作成されていることを検証
- VPCのDNS設定が有効化されていることを検証

**TestSubnetConfiguration**
- パブリックサブネットが作成されていることを検証
- パブリックサブネットが正しいCIDRブロックで作成されていることを検証
- パブリックサブネットがMulti-AZ構成であることを検証
- プライベートサブネットが作成されていることを検証
- プライベートサブネットが正しいCIDRブロックで作成されていることを検証
- プライベートサブネットがMulti-AZ構成であることを検証

**TestInternetGateway**
- Internet GatewayがVPCにアタッチされていることを検証

**TestNATGateway**
- NAT Gatewayがパブリックサブネットに配置されていることを検証
- NAT GatewayにElastic IPが割り当てられていることを検証
- Elastic IPが作成されていることを検証

**TestRouteTables**
- パブリックルートテーブルが存在することを検証
- パブリックルートテーブルにInternet Gatewayへのルートが設定されていることを検証
- プライベートルートテーブルが存在することを検証
- プライベートルートテーブルにNAT Gatewayへのルートが設定されていることを検証
- パブリックサブネットがパブリックルートテーブルに関連付けられていることを検証
- プライベートサブネットがプライベートルートテーブルに関連付けられていることを検証

## テスト実行方法

```bash
# すべてのテストを実行
pytest tests/ -v

# プロパティベーステストのみ実行
pytest tests/property/ -v --hypothesis-show-statistics

# 統合テストのみ実行
pytest tests/integration/ -v
```

## テスト結果の記録

テスト実行結果は `test-results/` ディレクトリに記録されます：

```
test-results/
├── property-tests-YYYYMMDD-HHMMSS.log
├── integration-tests-YYYYMMDD-HHMMSS.log
├── terraform-plan-YYYYMMDD-HHMMSS.log
└── security-scan-YYYYMMDD-HHMMSS.log
```

## 注意事項

- テストは既存のAWS CLIセッションを使用します
- テスト実行前に `aws login` でAWSに認証してください
- 統合テストは実際のAWSリソースを検証するため、AWS料金が発生する可能性があります
