#!/bin/bash
# エラーログ記録スクリプト
# Terraformやその他のコマンド実行時のエラーをログファイルに記録します

set -e

# ログディレクトリの作成
LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/logs"
mkdir -p "$LOG_DIR"

# ログファイル名（タイムスタンプ付き）
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ERROR_LOG="$LOG_DIR/error_${TIMESTAMP}.log"

# 関数: エラーログを記録
log_error() {
    local error_message="$1"
    local command="$2"
    local exit_code="$3"
    
    echo "========================================" >> "$ERROR_LOG"
    echo "エラー発生日時: $(date '+%Y-%m-%d %H:%M:%S')" >> "$ERROR_LOG"
    echo "コマンド: $command" >> "$ERROR_LOG"
    echo "終了コード: $exit_code" >> "$ERROR_LOG"
    echo "エラーメッセージ:" >> "$ERROR_LOG"
    echo "$error_message" >> "$ERROR_LOG"
    echo "========================================" >> "$ERROR_LOG"
    echo "" >> "$ERROR_LOG"
    
    echo "❌ エラーが発生しました。詳細は以下のログファイルを確認してください："
    echo "   $ERROR_LOG"
}

# 関数: Terraformコマンドを実行してエラーをログに記録
run_terraform_command() {
    local command="$1"
    local description="$2"
    
    echo "🔄 $description を実行中..."
    
    # コマンドを実行してエラーをキャプチャ
    if output=$(cd terraform && eval "$command" 2>&1); then
        echo "✅ $description が正常に完了しました"
        return 0
    else
        exit_code=$?
        log_error "$output" "$command" "$exit_code"
        return $exit_code
    fi
}

# 使用例
if [ "$#" -eq 0 ]; then
    echo "使用方法: $0 <command> [description]"
    echo ""
    echo "例:"
    echo "  $0 'terraform init' 'Terraform初期化'"
    echo "  $0 'terraform plan' 'Terraform実行計画'"
    echo "  $0 'terraform apply -auto-approve' 'Terraformデプロイ'"
    exit 1
fi

COMMAND="$1"
DESCRIPTION="${2:-コマンド実行}"

run_terraform_command "$COMMAND" "$DESCRIPTION"
