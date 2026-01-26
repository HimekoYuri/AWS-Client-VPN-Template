# ============================================================================
# AWS Client VPN 証明書生成スクリプト (PowerShell版)
# ============================================================================

# エラー時に停止
$ErrorActionPreference = "Stop"

# カラー出力用の関数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
    Write-ColorOutput "`n==> $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" "Green"
}

function Write-ErrorCustom {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" "Red"
}

function Write-WarningCustom {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" "Yellow"
}

# ============================================================================
# メイン処理
# ============================================================================

Write-ColorOutput @"

╔═══════════════════════════════════════════════════════════════╗
║   AWS Client VPN 証明書生成スクリプト (PowerShell版)         ║
╚═══════════════════════════════════════════════════════════════╝

"@ "Cyan"

# プロジェクトルートディレクトリに移動
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

Write-Step "環境チェック"

# Gitのインストール確認
try {
    $gitVersion = git --version
    Write-Success "Git がインストールされています: $gitVersion"
} catch {
    Write-ErrorCustom "Git がインストールされていません。"
    Write-Host "Git for Windows をインストールしてください: https://git-scm.com/download/win"
    exit 1
}

# ディレクトリの作成
Write-Step "ディレクトリの準備"

$certsDir = Join-Path $projectRoot "certs"
$easyRsaDir = Join-Path $projectRoot "easy-rsa"

if (-not (Test-Path $certsDir)) {
    New-Item -ItemType Directory -Path $certsDir | Out-Null
    Write-Success "certs ディレクトリを作成しました"
} else {
    Write-Success "certs ディレクトリは既に存在します"
}

# easy-rsaのダウンロード
Write-Step "easy-rsa のダウンロード"

if (Test-Path $easyRsaDir) {
    Write-WarningCustom "easy-rsa ディレクトリが既に存在します。削除して再ダウンロードしますか？ (Y/N)"
    $response = Read-Host
    if ($response -eq "Y" -or $response -eq "y") {
        Remove-Item -Recurse -Force $easyRsaDir
        Write-Success "既存の easy-rsa ディレクトリを削除しました"
    } else {
        Write-ColorOutput "既存の easy-rsa を使用します" "Yellow"
    }
}

if (-not (Test-Path $easyRsaDir)) {
    Write-Host "easy-rsa をGitHubからクローンしています..."
    git clone https://github.com/OpenVPN/easy-rsa.git $easyRsaDir
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorCustom "easy-rsa のダウンロードに失敗しました"
        exit 1
    }
    Write-Success "easy-rsa をダウンロードしました"
}

# easy-rsa 3のディレクトリに移動
$easyRsa3Dir = Join-Path $easyRsaDir "easyrsa3"
if (-not (Test-Path $easyRsa3Dir)) {
    Write-ErrorCustom "easy-rsa3 ディレクトリが見つかりません"
    exit 1
}

Set-Location $easyRsa3Dir

# Git Bashの検索
Write-Step "Git Bash の検索"

$gitBashPaths = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
)

$gitBash = $null
foreach ($path in $gitBashPaths) {
    if (Test-Path $path) {
        $gitBash = $path
        break
    }
}

if ($null -eq $gitBash) {
    Write-ErrorCustom "Git Bash が見つかりません"
    Write-Host "Git for Windows をインストールしてください: https://git-scm.com/download/win"
    exit 1
}

Write-Success "Git Bash が見つかりました: $gitBash"

# 証明書生成用のBashスクリプトを作成
Write-Step "証明書生成スクリプトの作成"

$bashScript = @"
#!/bin/bash
set -e

echo "==> PKI ディレクトリの初期化"
./easyrsa init-pki

echo "==> CA証明書の作成"
./easyrsa --batch --req-cn="AWS Client VPN CA" build-ca nopass

echo "==> サーバー証明書の作成"
./easyrsa --batch --req-cn="server" build-server-full server nopass

echo "==> クライアント証明書の作成"
./easyrsa --batch --req-cn="client1.vpn.example.com" build-client-full client1.vpn.example.com nopass

echo "==> 証明書のコピー"
cp pki/ca.crt "`$projectRoot/certs/"
cp pki/private/ca.key "`$projectRoot/certs/"
cp pki/issued/server.crt "`$projectRoot/certs/"
cp pki/private/server.key "`$projectRoot/certs/"
cp pki/issued/client1.vpn.example.com.crt "`$projectRoot/certs/"
cp pki/private/client1.vpn.example.com.key "`$projectRoot/certs/"

echo "==> 証明書の生成が完了しました"
"@

$bashScriptPath = Join-Path $easyRsa3Dir "generate-certs-internal.sh"
$bashScript | Out-File -FilePath $bashScriptPath -Encoding ASCII

Write-Success "証明書生成スクリプトを作成しました"

# Git Bashで証明書生成スクリプトを実行
Write-Step "証明書の生成"
Write-Host "Git Bash で証明書を生成しています。しばらくお待ちください..."

# パスをUnix形式に変換
$unixProjectRoot = $projectRoot -replace '\\', '/'
if ($unixProjectRoot -match '^([A-Z]):') {
    $driveLetter = $matches[1].ToLower()
    $unixProjectRoot = $unixProjectRoot -replace '^[A-Z]:', "/$driveLetter"
}

$unixEasyRsa3Dir = $easyRsa3Dir -replace '\\', '/'
if ($unixEasyRsa3Dir -match '^([A-Z]):') {
    $driveLetter = $matches[1].ToLower()
    $unixEasyRsa3Dir = $unixEasyRsa3Dir -replace '^[A-Z]:', "/$driveLetter"
}

# Git Bashで実行
$env:projectRoot = $unixProjectRoot
& $gitBash -c "cd '$unixEasyRsa3Dir' && chmod +x generate-certs-internal.sh && projectRoot='$unixProjectRoot' ./generate-certs-internal.sh"

if ($LASTEXITCODE -ne 0) {
    Write-ErrorCustom "証明書の生成に失敗しました"
    exit 1
}

# プロジェクトルートに戻る
Set-Location $projectRoot

# 証明書ファイルの確認
Write-Step "証明書ファイルの確認"

$certFiles = @(
    "certs/ca.crt",
    "certs/ca.key",
    "certs/server.crt",
    "certs/server.key",
    "certs/client1.vpn.example.com.crt",
    "certs/client1.vpn.example.com.key"
)

$allFilesExist = $true
foreach ($file in $certFiles) {
    if (Test-Path $file) {
        Write-Success "$file が生成されました"
    } else {
        Write-ErrorCustom "$file が見つかりません"
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-ErrorCustom "一部の証明書ファイルが生成されませんでした"
    exit 1
}

# 証明書情報の表示
Write-Step "証明書情報の確認"

try {
    Write-Host "`nCA証明書の情報:"
    & openssl x509 -in certs/ca.crt -noout -subject -dates 2>$null
    
    Write-Host "`nサーバー証明書の情報:"
    & openssl x509 -in certs/server.crt -noout -subject -dates 2>$null
    
    Write-Host "`nクライアント証明書の情報:"
    & openssl x509 -in certs/client1.vpn.example.com.crt -noout -subject -dates 2>$null
} catch {
    Write-WarningCustom "OpenSSLがインストールされていないため、証明書情報を表示できません"
}

# 完了メッセージ
Write-ColorOutput @"

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

⚠ セキュリティ注意事項:
  - 秘密鍵ファイル (*.key) は絶対にGitにコミットしないでください
  - .gitignore で除外されていることを確認してください
  - 秘密鍵ファイルは安全な場所に保管してください

次のステップ:
  1. terraform/acm.tf で証明書をACMにインポートする設定を確認
  2. terraform apply を実行してAWSリソースを作成
  3. docs/certificate-distribution.md でクライアント証明書の配布手順を確認

"@ "Green"
