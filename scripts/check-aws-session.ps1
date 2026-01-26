# AWS CLIセッション確認スクリプト (PowerShell)
# AWS CLIセッションが有効かどうかを確認し、期限切れの場合は再認証を促します

# エラー時に停止
$ErrorActionPreference = "Stop"

# 関数: AWS認証情報を確認
function Test-AWSCredentials {
    Write-Host "🔍 AWS認証情報を確認中..." -ForegroundColor Cyan
    
    # AWS CLIがインストールされているか確認
    try {
        $null = Get-Command aws -ErrorAction Stop
    }
    catch {
        Write-Host "❌ AWS CLIがインストールされていません" -ForegroundColor Red
        Write-Host "AWS CLIをインストールしてください: https://aws.amazon.com/cli/" -ForegroundColor Yellow
        return $false
    }
    
    # AWS認証情報が設定されているか確認
    try {
        $identity = aws sts get-caller-identity 2>&1 | ConvertFrom-Json
        
        if ($LASTEXITCODE -ne 0) {
            throw "認証情報が無効です"
        }
        
        Write-Host "✅ AWS認証情報が有効です" -ForegroundColor Green
        Write-Host ""
        Write-Host "認証情報の詳細:" -ForegroundColor Cyan
        Write-Host "  アカウントID: $($identity.Account)" -ForegroundColor Green
        Write-Host "  ユーザーARN: $($identity.Arn)" -ForegroundColor Green
        Write-Host "  ユーザーID: $($identity.UserId)" -ForegroundColor Green
        
        # 期待されるアカウントIDと比較
        $expectedAccountId = "620360464874"
        if ($identity.Account -ne $expectedAccountId) {
            Write-Host ""
            Write-Host "⚠️  警告: 期待されるアカウントID ($expectedAccountId) と異なります" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Host "❌ AWS認証情報が無効または期限切れです" -ForegroundColor Red
        Write-Host ""
        Write-Host "以下のコマンドで再認証してください：" -ForegroundColor Yellow
        Write-Host "  aws login" -ForegroundColor Green
        Write-Host ""
        Write-Host "または、環境変数を設定してください：" -ForegroundColor Yellow
        Write-Host "  `$env:AWS_PROFILE = 'your-profile'" -ForegroundColor Green
        return $false
    }
}

# 関数: セッションの有効期限を確認
function Test-SessionExpiration {
    Write-Host ""
    Write-Host "🕐 セッションの有効期限を確認中..." -ForegroundColor Cyan
    
    # 環境変数からセッショントークンの有無を確認
    if ($env:AWS_SESSION_TOKEN) {
        Write-Host "⚠️  一時的な認証情報（セッショントークン）を使用しています" -ForegroundColor Yellow
        Write-Host "   セッションが期限切れになった場合は、再度 'aws login' を実行してください" -ForegroundColor Yellow
    }
    else {
        Write-Host "✅ 永続的な認証情報を使用しています" -ForegroundColor Green
    }
}

# 関数: AWS リージョンを確認
function Test-AWSRegion {
    Write-Host ""
    Write-Host "🌏 AWSリージョンを確認中..." -ForegroundColor Cyan
    
    $region = $env:AWS_REGION
    if (-not $region) {
        $region = $env:AWS_DEFAULT_REGION
    }
    if (-not $region) {
        # AWS CLIの設定から取得を試みる
        try {
            $region = aws configure get region 2>$null
        }
        catch {
            $region = $null
        }
    }
    
    if (-not $region) {
        Write-Host "⚠️  AWSリージョンが設定されていません" -ForegroundColor Yellow
        Write-Host "   デフォルトリージョンを設定することを推奨します：" -ForegroundColor Yellow
        Write-Host "     `$env:AWS_REGION = 'ap-northeast-1'" -ForegroundColor Green
        Write-Host "     または" -ForegroundColor Green
        Write-Host "     aws configure set region ap-northeast-1" -ForegroundColor Green
    }
    else {
        Write-Host "✅ AWSリージョン: $region" -ForegroundColor Green
        
        # 期待されるリージョンと比較
        $expectedRegion = "ap-northeast-1"
        if ($region -ne $expectedRegion) {
            Write-Host "⚠️  警告: 期待されるリージョン ($expectedRegion) と異なります" -ForegroundColor Yellow
        }
    }
}

# 関数: 必要なAWS権限を確認
function Test-AWSPermissions {
    Write-Host ""
    Write-Host "🔐 AWS権限を確認中..." -ForegroundColor Cyan
    
    $permissionsOk = $true
    
    # VPC権限を確認
    try {
        $null = aws ec2 describe-vpcs --max-results 1 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ VPC権限: OK" -ForegroundColor Green
        }
        else {
            throw "VPC権限がありません"
        }
    }
    catch {
        Write-Host "❌ VPC権限: NG" -ForegroundColor Red
        $permissionsOk = $false
    }
    
    # Client VPN権限を確認
    try {
        $null = aws ec2 describe-client-vpn-endpoints --max-results 1 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Client VPN権限: OK" -ForegroundColor Green
        }
        else {
            throw "Client VPN権限がありません"
        }
    }
    catch {
        Write-Host "❌ Client VPN権限: NG" -ForegroundColor Red
        $permissionsOk = $false
    }
    
    # ACM権限を確認
    try {
        $null = aws acm list-certificates --max-items 1 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ ACM権限: OK" -ForegroundColor Green
        }
        else {
            throw "ACM権限がありません"
        }
    }
    catch {
        Write-Host "❌ ACM権限: NG" -ForegroundColor Red
        $permissionsOk = $false
    }
    
    # CloudWatch Logs権限を確認
    try {
        $null = aws logs describe-log-groups --max-items 1 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ CloudWatch Logs権限: OK" -ForegroundColor Green
        }
        else {
            throw "CloudWatch Logs権限がありません"
        }
    }
    catch {
        Write-Host "❌ CloudWatch Logs権限: NG" -ForegroundColor Red
        $permissionsOk = $false
    }
    
    if (-not $permissionsOk) {
        Write-Host ""
        Write-Host "❌ 必要な権限が不足しています" -ForegroundColor Red
        Write-Host "IAM管理者に連絡して、必要な権限を付与してもらってください" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "✅ すべての必要な権限が付与されています" -ForegroundColor Green
    return $true
}

# メイン処理
function Main {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  AWS CLIセッション確認" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # AWS認証情報を確認
    if (-not (Test-AWSCredentials)) {
        exit 1
    }
    
    # セッションの有効期限を確認
    Test-SessionExpiration
    
    # AWSリージョンを確認
    Test-AWSRegion
    
    # AWS権限を確認
    if (-not (Test-AWSPermissions)) {
        exit 1
    }
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "✅ すべてのチェックが完了しました" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
}

# スクリプトを実行
Main
