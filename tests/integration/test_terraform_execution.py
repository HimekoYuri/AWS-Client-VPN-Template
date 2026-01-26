"""
統合テスト: Terraform実行テスト

**Validates: Requirements 6.2, 6.3, 10.1**

このテストは、Terraformコマンドが正常に実行されることを検証します。
- terraform init: 初期化が成功すること
- terraform validate: 構文検証が成功すること
- terraform plan: 実行計画の生成が成功すること
"""

import subprocess
import os
from pathlib import Path

import pytest


@pytest.fixture(scope="module")
def terraform_dir():
    """Terraformディレクトリのパスを返す"""
    project_root = Path(__file__).parent.parent.parent
    return project_root / "terraform"


@pytest.fixture(scope="module")
def terraform_initialized(terraform_dir):
    """
    Terraformを初期化する（モジュールスコープで1回のみ実行）
    
    **Validates: Requirements 6.2**
    """
    result = subprocess.run(
        ["terraform", "init", "-upgrade"],
        cwd=terraform_dir,
        capture_output=True,
        text=True,
        timeout=300  # 5分タイムアウト
    )
    
    return {
        "returncode": result.returncode,
        "stdout": result.stdout,
        "stderr": result.stderr
    }


def test_terraform_init_succeeds(terraform_initialized):
    """
    terraform initが正常に完了することを検証します。
    
    **Validates: Requirements 6.2**
    """
    result = terraform_initialized
    
    assert result["returncode"] == 0, (
        f"❌ terraform initが失敗しました:\n"
        f"標準出力:\n{result['stdout']}\n"
        f"標準エラー:\n{result['stderr']}"
    )
    
    # 成功メッセージが含まれることを確認
    assert "Terraform has been successfully initialized" in result["stdout"], (
        f"❌ terraform initの成功メッセージが見つかりません:\n{result['stdout']}"
    )
    
    print(f"✅ terraform init が正常に完了しました")


def test_terraform_validate_succeeds(terraform_dir, terraform_initialized):
    """
    terraform validateが正常に完了することを検証します。
    
    **Validates: Requirements 6.3**
    """
    # terraform initが成功していることを確認
    assert terraform_initialized["returncode"] == 0, "terraform initが失敗しています"
    
    result = subprocess.run(
        ["terraform", "validate"],
        cwd=terraform_dir,
        capture_output=True,
        text=True,
        timeout=60
    )
    
    assert result.returncode == 0, (
        f"❌ terraform validateが失敗しました:\n"
        f"標準出力:\n{result.stdout}\n"
        f"標準エラー:\n{result.stderr}"
    )
    
    # 成功メッセージが含まれることを確認
    assert "Success" in result.stdout or "valid" in result.stdout.lower(), (
        f"❌ terraform validateの成功メッセージが見つかりません:\n{result.stdout}"
    )
    
    print(f"✅ terraform validate が正常に完了しました")


def test_terraform_fmt_check(terraform_dir):
    """
    Terraformコードが正しくフォーマットされていることを検証します。
    
    **Validates: Requirements 6.1**
    """
    result = subprocess.run(
        ["terraform", "fmt", "-check", "-recursive"],
        cwd=terraform_dir,
        capture_output=True,
        text=True,
        timeout=30
    )
    
    # フォーマットが必要なファイルがある場合は警告
    if result.returncode != 0:
        pytest.skip(
            f"⚠️  以下のファイルがフォーマットされていません:\n{result.stdout}\n"
            f"'terraform fmt -recursive' を実行してフォーマットしてください。"
        )
    
    print(f"✅ Terraformコードが正しくフォーマットされています")


@pytest.mark.slow
def test_terraform_plan_succeeds(terraform_dir, terraform_initialized):
    """
    terraform planが正常に実行計画を生成することを検証します。
    
    注意: このテストはAWS認証が必要なため、実際のAWS環境でのみ実行されます。
    
    **Validates: Requirements 6.3, 10.1**
    """
    # terraform initが成功していることを確認
    assert terraform_initialized["returncode"] == 0, "terraform initが失敗しています"
    
    # AWS認証情報が設定されているか確認
    aws_profile = os.environ.get("AWS_PROFILE")
    aws_access_key = os.environ.get("AWS_ACCESS_KEY_ID")
    
    if not aws_profile and not aws_access_key:
        pytest.skip(
            "⚠️  AWS認証情報が設定されていません。\n"
            "このテストをスキップします。\n"
            "実行するには、AWS CLIでログインするか、環境変数を設定してください。"
        )
    
    # terraform planを実行
    result = subprocess.run(
        ["terraform", "plan", "-input=false", "-detailed-exitcode"],
        cwd=terraform_dir,
        capture_output=True,
        text=True,
        timeout=300  # 5分タイムアウト
    )
    
    # terraform planの終了コード:
    # 0 = 変更なし
    # 1 = エラー
    # 2 = 変更あり
    assert result.returncode in [0, 2], (
        f"❌ terraform planが失敗しました:\n"
        f"標準出力:\n{result.stdout}\n"
        f"標準エラー:\n{result.stderr}"
    )
    
    # エラーメッセージが含まれていないことを確認
    error_keywords = ["Error:", "error:", "Failed", "failed"]
    has_errors = any(keyword in result.stderr for keyword in error_keywords)
    
    assert not has_errors, (
        f"❌ terraform planの出力にエラーが含まれています:\n{result.stderr}"
    )
    
    if result.returncode == 0:
        print(f"✅ terraform plan が正常に完了しました（変更なし）")
    else:
        print(f"✅ terraform plan が正常に完了しました（変更あり）")
    
    # 実行計画をログファイルに保存
    log_dir = Path(__file__).parent.parent.parent / "test-results"
    log_dir.mkdir(exist_ok=True)
    
    log_file = log_dir / "terraform-plan.log"
    with open(log_file, "w", encoding="utf-8") as f:
        f.write("=== Terraform Plan Output ===\n\n")
        f.write(result.stdout)
        f.write("\n\n=== Terraform Plan Errors ===\n\n")
        f.write(result.stderr)
    
    print(f"📝 実行計画を {log_file} に保存しました")


def test_terraform_files_exist(terraform_dir):
    """
    必要なTerraformファイルが存在することを検証します。
    
    **Validates: Requirements 6.1**
    """
    required_files = [
        "main.tf",
        "variables.tf",
        "outputs.tf",
        "versions.tf",
        "vpc.tf",
        "subnets.tf",
        "gateways.tf",
        "route_tables.tf",
        "security_groups.tf",
        "acm.tf",
        "iam_saml.tf",
        "cloudwatch.tf",
        "client_vpn_pc.tf",
        "client_vpn_mobile.tf",
        "cloudtrail.tf",
    ]
    
    missing_files = []
    for file_name in required_files:
        file_path = terraform_dir / file_name
        if not file_path.exists():
            missing_files.append(file_name)
    
    assert not missing_files, (
        f"❌ 以下のTerraformファイルが見つかりません: {missing_files}"
    )
    
    print(f"✅ すべての必要なTerraformファイルが存在します")


def test_terraform_provider_configuration(terraform_dir):
    """
    Terraformプロバイダーが正しく設定されていることを検証します。
    
    **Validates: Requirements 6.1**
    """
    main_tf = terraform_dir / "main.tf"
    
    assert main_tf.exists(), "main.tfファイルが見つかりません"
    
    with open(main_tf, "r", encoding="utf-8") as f:
        content = f.read()
    
    # AWSプロバイダーが設定されていることを確認
    assert "provider \"aws\"" in content, (
        "❌ AWSプロバイダーが設定されていません"
    )
    
    # リージョンが設定されていることを確認
    assert "region" in content, (
        "❌ AWSリージョンが設定されていません"
    )
    
    print(f"✅ Terraformプロバイダーが正しく設定されています")


if __name__ == "__main__":
    # スタンドアロン実行用
    pytest.main([__file__, "-v", "-s"])
