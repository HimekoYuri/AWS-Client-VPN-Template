#!/bin/bash
# ============================================================================
# AWS Client VPN 証明書生成スクリプト (Bash版)
# ============================================================================
# 
# このスクリプトは、AWS Client VPNで使用する証明書を生成します。
# easy-rsaを使用して、CA証明書、サーバー証明書、クライアント証明書を作成します。
#
# 前提条件:
#   - Git がインストールされていること
#   - インターネット接続があること
#
# 使用方法:
#   bash scripts/generate-certs.sh
#   または
#   chmod +x scripts/generate-certs.sh
#   ./scripts/generate-certs.sh
#
# 生成される証明書:
#   - certs/ca.crt              : ルートCA証明書
#   - certs/ca.key              : ルートCA秘密鍵
#   - certs/server.crt          : サーバー証明書
#   - certs/server.key          : サーバー秘密鍵
#   - certs/client1.vpn.example.com.crt : クライアント証明書
#   - certs/client1.vpn.example.com.key : クライアント秘密鍵
#
# セキュリティ注意事項:
#   - 生成された秘密鍵ファイル(*.key)は絶対にGitにコミットしないでください
#   - .gitignoreで除外されていることを確認してください
#
# ============================================================================

set -e  # エラー時に停止

# カラー出力用の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ステップ表示用の関数
print_step() {
    echo -e "\n${CYAN}==> $1${NC}"
}

# 成功メッセージ用の関数
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# エラーメッセージ用の関数
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# 警告メッセージ用の関数
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# ============================================================================
# メイン処理
# ============================================================================

echo -e "${CYAN}"
cat << "EOF"

╔═══════════════════════════════════════════════════════════════╗
║   AWS Client VPN 証明書生成スクリプト (Bash版)               ║
╚═══════════════════════════════════════════════════════════════╝

EOF
echo -e "${NC}"

# プロジェクトルートディレクトリに移動
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

print_step "環境チェック"

# Gitのインストール確認
if ! command -v git &> /dev/null; then
    print_error "Git がインストールされていません"
    echo "Git をインストールしてください: https://git-scm.com/"
    exit 1
fi
print_success "Git がインストールされています: $(git --version)"

# ディレクトリの作成
print_step "ディレクトリの準備"

CERTS_DIR="$PROJECT_ROOT/certs"
EASY_RSA_DIR="$PROJECT_ROOT/easy-rsa"

if [ ! -d "$CERTS_DIR" ]; then
    mkdir -p "$CERTS_DIR"
    print_success "certs ディレクトリを作成しました"
else
    print_success "certs ディレクトリは既に存在します"
fi

# easy-rsaのダウンロード
print_step "easy-rsa のダウンロード"

if [ -d "$EASY_RSA_DIR" ]; then
    print_warning "easy-rsa ディレクトリが既に存在します。削除して再ダウンロードしますか？ (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf "$EASY_RSA_DIR"
        print_success "既存の easy-rsa ディレクトリを削除しました"
    else
        print_warning "既存の easy-rsa を使用します"
    fi
fi

if [ ! -d "$EASY_RSA_DIR" ]; then
    echo "easy-rsa をGitHubからクローンしています..."
    git clone https://github.com/OpenVPN/easy-rsa.git "$EASY_RSA_DIR"
    print_success "easy-rsa をダウンロードしました"
fi

# easy-rsa 3のディレクトリに移動
EASY_RSA3_DIR="$EASY_RSA_DIR/easyrsa3"
if [ ! -d "$EASY_RSA3_DIR" ]; then
    print_error "easy-rsa3 ディレクトリが見つかりません"
    exit 1
fi

cd "$EASY_RSA3_DIR"

# PKIディレクトリの初期化
print_step "PKI ディレクトリの初期化"

if [ -d "pki" ]; then
    print_warning "PKI ディレクトリが既に存在します。削除して再初期化しますか？ (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf pki
        print_success "既存の PKI ディレクトリを削除しました"
    else
        print_warning "既存の PKI を使用します（証明書が既に存在する場合はスキップされます）"
    fi
fi

./easyrsa init-pki
print_success "PKI ディレクトリを初期化しました"

# CA証明書の作成
print_step "CA証明書の作成"

if [ -f "pki/ca.crt" ]; then
    print_warning "CA証明書が既に存在します。スキップします"
else
    ./easyrsa --batch --req-cn="AWS Client VPN CA" build-ca nopass
    print_success "CA証明書を作成しました"
fi

# サーバー証明書の作成
print_step "サーバー証明書の作成"

if [ -f "pki/issued/server.crt" ]; then
    print_warning "サーバー証明書が既に存在します。スキップします"
else
    ./easyrsa --batch --req-cn="server" build-server-full server nopass
    print_success "サーバー証明書を作成しました"
fi

# クライアント証明書の作成
print_step "クライアント証明書の作成"

if [ -f "pki/issued/client1.vpn.example.com.crt" ]; then
    print_warning "クライアント証明書が既に存在します。スキップします"
else
    ./easyrsa --batch --req-cn="client1.vpn.example.com" build-client-full client1.vpn.example.com nopass
    print_success "クライアント証明書を作成しました"
fi

# 証明書のコピー
print_step "証明書のコピー"

cp pki/ca.crt "$CERTS_DIR/"
cp pki/private/ca.key "$CERTS_DIR/"
cp pki/issued/server.crt "$CERTS_DIR/"
cp pki/private/server.key "$CERTS_DIR/"
cp pki/issued/client1.vpn.example.com.crt "$CERTS_DIR/"
cp pki/private/client1.vpn.example.com.key "$CERTS_DIR/"

print_success "証明書を certs/ ディレクトリにコピーしました"

# プロジェクトルートに戻る
cd "$PROJECT_ROOT"

# 証明書ファイルの確認
print_step "証明書ファイルの確認"

CERT_FILES=(
    "certs/ca.crt"
    "certs/ca.key"
    "certs/server.crt"
    "certs/server.key"
    "certs/client1.vpn.example.com.crt"
    "certs/client1.vpn.example.com.key"
)

ALL_FILES_EXIST=true
for file in "${CERT_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "$file が生成されました"
    else
        print_error "$file が見つかりません"
        ALL_FILES_EXIST=false
    fi
done

if [ "$ALL_FILES_EXIST" = false ]; then
    print_error "一部の証明書ファイルが生成されませんでした"
    exit 1
fi

# 証明書情報の表示
print_step "証明書情報の確認"

if command -v openssl &> /dev/null; then
    echo -e "\nCA証明書の情報:"
    openssl x509 -in certs/ca.crt -noout -subject -dates
    
    echo -e "\nサーバー証明書の情報:"
    openssl x509 -in certs/server.crt -noout -subject -dates
    
    echo -e "\nクライアント証明書の情報:"
    openssl x509 -in certs/client1.vpn.example.com.crt -noout -subject -dates
else
    print_warning "OpenSSLがインストールされていないため、証明書情報を表示できません"
fi

# 完了メッセージ
echo -e "${GREEN}"
cat << "EOF"

╔═══════════════════════════════════════════════════════════════╗
║                  証明書の生成が完了しました！                 ║
╚═══════════════════════════════════════════════════════════════╝

生成された証明書:
  ✓ certs/ca.crt                          (CA証明書)
  ✓ certs/ca.key                          (CA秘密鍵)
  ✓ certs/server.crt                      (サーバー証明書)
  ✓ certs/server.key                      (サーバー秘密鍵)
  ✓ certs/client1.vpn.example.com.crt     (クライアント証明書)
  ✓ certs/client1.vpn.example.com.key     (クライアント秘密鍵)

EOF
echo -e "${NC}"

echo -e "${YELLOW}"
cat << "EOF"
⚠ セキュリティ注意事項:
  - 秘密鍵ファイル (*.key) は絶対にGitにコミットしないでください
  - .gitignore で除外されていることを確認してください
  - 秘密鍵ファイルは安全な場所に保管してください

次のステップ:
  1. terraform/acm.tf で証明書をACMにインポートする設定を確認
  2. terraform apply を実行してAWSリソースを作成
  3. docs/certificate-distribution.md でクライアント証明書の配布手順を確認

EOF
echo -e "${NC}"
