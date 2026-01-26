# エラーログ記録スクリプト (PowerShell)
# Terraformやその他のコマンド実行時のエラーをログファイルに記録します

param(
    [Parameter(Mandatory=$true)]
    [string]$Command,
    
    [Parameter(Mandatory=$false)]
    [string]$Description = "コマンド実行"
)

# エラー時に停止
$ErrorActionPreference = "Stop"

# ログディレクトリの作成
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$LogDir = Join-Path $ProjectRoot "logs"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

# ログファイル名（タイムスタンプ付き）
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ErrorLog = Join-Path $LogDir "error_$Timestamp.log"

# 関数: エラーログを記録
function Write-ErrorLog {
    param(
        [string]$ErrorMessage,
        [string]$Command,
        [int]$ExitCode
    )
    
    $LogContent = @"
========================================
エラー発生日時: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
コマンド: $Command
終了コード: $ExitCode
エラーメッセージ:
$ErrorMessage
========================================

"@
    
    Add-Content -Path $ErrorLog -Value $LogContent
    
    Write-Host "❌ エラーが発生しました。詳細は以下のログファイルを確認してください：" -ForegroundColor Red
    Write-Host "   $ErrorLog" -ForegroundColor Yellow
}

# 関数: Terraformコマンドを実行してエラーをログに記録
function Invoke-TerraformCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "🔄 $Description を実行中..." -ForegroundColor Cyan
    
    try {
        # Terraformディレクトリに移動
        $TerraformDir = Join-Path $ProjectRoot "terraform"
        Push-Location $TerraformDir
        
        # コマンドを実行
        $Output = Invoke-Expression $Command 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $Description が正常に完了しました" -ForegroundColor Green
            return $true
        } else {
            Write-ErrorLog -ErrorMessage ($Output | Out-String) -Command $Command -ExitCode $LASTEXITCODE
            return $false
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Command $Command -ExitCode 1
        return $false
    }
    finally {
        Pop-Location
    }
}

# メイン処理
if (-not $Command) {
    Write-Host "使用方法: .\log-errors.ps1 -Command <command> [-Description <description>]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "例:" -ForegroundColor Yellow
    Write-Host "  .\log-errors.ps1 -Command 'terraform init' -Description 'Terraform初期化'"
    Write-Host "  .\log-errors.ps1 -Command 'terraform plan' -Description 'Terraform実行計画'"
    Write-Host "  .\log-errors.ps1 -Command 'terraform apply -auto-approve' -Description 'Terraformデプロイ'"
    exit 1
}

$Result = Invoke-TerraformCommand -Command $Command -Description $Description

if (-not $Result) {
    exit 1
}
