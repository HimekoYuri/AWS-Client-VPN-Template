#!/bin/bash

# AWS認証情報を環境変数に設定
eval $(aws configure export-credentials --format env)

# Terraform planを実行
echo "=== Terraform Plan 実行開始 ==="
terraform plan -no-color

echo ""
echo "=== Terraform Plan 実行完了 ==="
