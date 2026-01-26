#!/bin/bash
# AWS CLIセッション確認スクリプト
# AWS CLIセッションが有効かどうかを確認し、期限切れの場合は再認証を促します

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 関数: AWS認証情報を確認
check_aws_credentials() {
    echo -e "${BLUE}🔍 AWS認証情報を確認中...${NC}"
    
    # AWS CLIがインストールされているか確認
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLIがインストールされていません${NC}"
        echo -e "${YELLOW}AWS CLIをインストールしてください: https://aws.amazon.com/cli/${NC}"
        return 1
    fi
    
    # AWS認証情報が設定されているか確認
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS認証情報が無効または期限切れです${NC}"
        echo ""
        echo -e "${YELLOW}以下のコマンドで再認証してください：${NC}"
        echo -e "  ${GREEN}aws login${NC}"
        echo ""
        echo -e "${YELLOW}または、環境変数を設定してください：${NC}"
        echo -e "  ${GREEN}export AWS_PROFILE=your-profile${NC}"
        return 1
    fi
    
    # 認証情報の詳細を取得
    local identity=$(aws sts get-caller-identity 2>&1)
    
    if [ $? -eq 0 ]; then
        local account_id=$(echo "$identity" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
        local user_arn=$(echo "$identity" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
        local user_id=$(echo "$identity" | grep -o '"UserId": "[^"]*"' | cut -d'"' -f4)
        
        echo -e "${GREEN}✅ AWS認証情報が有効です${NC}"
        echo ""
        echo -e "${BLUE}認証情報の詳細:${NC}"
        echo -e "  アカウントID: ${GREEN}$account_id${NC}"
        echo -e "  ユーザーARN: ${GREEN}$user_arn${NC}"
        echo -e "  ユーザーID: ${GREEN}$user_id${NC}"
        
        # 期待されるアカウントIDと比較
        local expected_account_id="620360464874"
        if [ "$account_id" != "$expected_account_id" ]; then
            echo ""
            echo -e "${YELLOW}⚠️  警告: 期待されるアカウントID ($expected_account_id) と異なります${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}❌ AWS認証情報の取得に失敗しました${NC}"
        echo "$identity"
        return 1
    fi
}

# 関数: セッションの有効期限を確認（可能な場合）
check_session_expiration() {
    echo ""
    echo -e "${BLUE}🕐 セッションの有効期限を確認中...${NC}"
    
    # 環境変数からセッショントークンの有無を確認
    if [ -n "$AWS_SESSION_TOKEN" ]; then
        echo -e "${YELLOW}⚠️  一時的な認証情報（セッショントークン）を使用しています${NC}"
        echo -e "${YELLOW}   セッションが期限切れになった場合は、再度 'aws login' を実行してください${NC}"
    else
        echo -e "${GREEN}✅ 永続的な認証情報を使用しています${NC}"
    fi
}

# 関数: AWS リージョンを確認
check_aws_region() {
    echo ""
    echo -e "${BLUE}🌏 AWSリージョンを確認中...${NC}"
    
    local region="${AWS_REGION:-${AWS_DEFAULT_REGION:-未設定}}"
    
    if [ "$region" = "未設定" ]; then
        # AWS CLIの設定から取得を試みる
        region=$(aws configure get region 2>/dev/null || echo "未設定")
    fi
    
    if [ "$region" = "未設定" ]; then
        echo -e "${YELLOW}⚠️  AWSリージョンが設定されていません${NC}"
        echo -e "${YELLOW}   デフォルトリージョンを設定することを推奨します：${NC}"
        echo -e "     ${GREEN}export AWS_REGION=ap-northeast-1${NC}"
        echo -e "     ${GREEN}または${NC}"
        echo -e "     ${GREEN}aws configure set region ap-northeast-1${NC}"
    else
        echo -e "${GREEN}✅ AWSリージョン: $region${NC}"
        
        # 期待されるリージョンと比較
        local expected_region="ap-northeast-1"
        if [ "$region" != "$expected_region" ]; then
            echo -e "${YELLOW}⚠️  警告: 期待されるリージョン ($expected_region) と異なります${NC}"
        fi
    fi
}

# 関数: 必要なAWS権限を確認
check_aws_permissions() {
    echo ""
    echo -e "${BLUE}🔐 AWS権限を確認中...${NC}"
    
    local permissions_ok=true
    
    # VPC権限を確認
    if aws ec2 describe-vpcs --max-results 1 &> /dev/null; then
        echo -e "${GREEN}✅ VPC権限: OK${NC}"
    else
        echo -e "${RED}❌ VPC権限: NG${NC}"
        permissions_ok=false
    fi
    
    # Client VPN権限を確認
    if aws ec2 describe-client-vpn-endpoints --max-results 1 &> /dev/null; then
        echo -e "${GREEN}✅ Client VPN権限: OK${NC}"
    else
        echo -e "${RED}❌ Client VPN権限: NG${NC}"
        permissions_ok=false
    fi
    
    # ACM権限を確認
    if aws acm list-certificates --max-items 1 &> /dev/null; then
        echo -e "${GREEN}✅ ACM権限: OK${NC}"
    else
        echo -e "${RED}❌ ACM権限: NG${NC}"
        permissions_ok=false
    fi
    
    # CloudWatch Logs権限を確認
    if aws logs describe-log-groups --max-items 1 &> /dev/null; then
        echo -e "${GREEN}✅ CloudWatch Logs権限: OK${NC}"
    else
        echo -e "${RED}❌ CloudWatch Logs権限: NG${NC}"
        permissions_ok=false
    fi
    
    if [ "$permissions_ok" = false ]; then
        echo ""
        echo -e "${RED}❌ 必要な権限が不足しています${NC}"
        echo -e "${YELLOW}IAM管理者に連絡して、必要な権限を付与してもらってください${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ すべての必要な権限が付与されています${NC}"
    return 0
}

# メイン処理
main() {
    echo ""
    echo "=========================================="
    echo "  AWS CLIセッション確認"
    echo "=========================================="
    echo ""
    
    # AWS認証情報を確認
    if ! check_aws_credentials; then
        exit 1
    fi
    
    # セッションの有効期限を確認
    check_session_expiration
    
    # AWSリージョンを確認
    check_aws_region
    
    # AWS権限を確認
    if ! check_aws_permissions; then
        exit 1
    fi
    
    echo ""
    echo "=========================================="
    echo -e "${GREEN}✅ すべてのチェックが完了しました${NC}"
    echo "=========================================="
    echo ""
}

# スクリプトを実行
main
