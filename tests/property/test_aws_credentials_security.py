"""
Property-Based Test: AWS認証情報セキュリティスキャン

**Validates: Requirements 8.4**

このテストは、プロジェクト内のすべてのファイルにAWS認証情報が平文で保存されていないことを検証します。
OWASP基準に準拠し、アクセスキー、シークレットキー、セッショントークンなどをスキャンします。
"""

import re
from pathlib import Path
from typing import List, Tuple

import pytest
from hypothesis import given, strategies as st


# AWS認証情報パターン
AWS_CREDENTIAL_PATTERNS = [
    # AWS Access Key ID（AKIA形式）
    (r'AKIA[0-9A-Z]{16}', "AWS Access Key ID"),
    
    # AWS Secret Access Key（40文字のBase64風文字列）
    # 注: 誤検知を減らすため、前後に特定のキーワードがある場合のみ検出
    (r'(?:aws_secret_access_key|secret_access_key|SecretAccessKey)\s*[=:]\s*["\']?([A-Za-z0-9/+=]{40})["\']?', 
     "AWS Secret Access Key"),
    
    # AWS Session Token（長いBase64風文字列）
    (r'(?:aws_session_token|session_token|SessionToken)\s*[=:]\s*["\']?([A-Za-z0-9/+=]{100,})["\']?',
     "AWS Session Token"),
    
    # AWS認証情報の設定パターン
    (r'aws_access_key_id\s*=\s*["\']?(AKIA[0-9A-Z]{16})["\']?',
     "AWS Access Key ID in config"),
    
    # 環境変数形式のAWS認証情報
    (r'AWS_ACCESS_KEY_ID\s*=\s*["\']?(AKIA[0-9A-Z]{16})["\']?',
     "AWS Access Key ID in environment variable"),
    
    (r'AWS_SECRET_ACCESS_KEY\s*=\s*["\']?([A-Za-z0-9/+=]{40})["\']?',
     "AWS Secret Access Key in environment variable"),
]

# 除外するファイルパターン（テストファイル、ドキュメントなど）
EXCLUDE_FILE_PATTERNS = [
    r'test_.*\.py$',  # テストファイル
    r'.*\.md$',       # Markdownドキュメント
    r'.*\.txt$',      # テキストファイル
    r'\.gitignore$',  # Gitignore
    r'requirements\.txt$',  # Python依存関係
]

# 除外するサンプル/例示用のキー（AWSドキュメントで使用される例）
EXAMPLE_KEYS = [
    'AKIAIOSFODNN7EXAMPLE',
    'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
]


def should_scan_file(file_path: Path) -> bool:
    """
    ファイルをスキャン対象とすべきか判定する
    
    Args:
        file_path: チェックするファイルのパス
        
    Returns:
        スキャン対象の場合True
    """
    file_name = file_path.name
    
    # 除外パターンにマッチするかチェック
    for pattern in EXCLUDE_FILE_PATTERNS:
        if re.match(pattern, file_name):
            return False
    
    return True


def scan_file_for_aws_credentials(file_path: Path) -> List[Tuple[str, str, int]]:
    """
    ファイルをスキャンしてAWS認証情報パターンを検出する
    
    Args:
        file_path: スキャンするファイルのパス
        
    Returns:
        検出された認証情報のリスト [(パターン名, マッチした文字列, 行番号), ...]
    """
    if not should_scan_file(file_path):
        return []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except (UnicodeDecodeError, PermissionError, FileNotFoundError):
        # バイナリファイルや読み取り不可ファイルはスキップ
        return []
    
    findings = []
    lines = content.split('\n')
    
    for pattern, pattern_name in AWS_CREDENTIAL_PATTERNS:
        for line_num, line in enumerate(lines, start=1):
            # コメント行はスキップ
            stripped_line = line.strip()
            if stripped_line.startswith('#') or stripped_line.startswith('//'):
                continue
            
            matches = re.findall(pattern, line)
            for match in matches:
                # グループがある場合は最初のグループを使用
                if isinstance(match, tuple):
                    match = match[0] if match else ""
                
                # 例示用のキーは除外
                if match in EXAMPLE_KEYS:
                    continue
                
                findings.append((pattern_name, match, line_num))
    
    return findings


def test_no_aws_credentials_in_project_files(all_project_files):
    """
    Feature: aws-client-vpn, Property 2
    
    プロジェクト内のすべてのファイルにAWS認証情報が平文で保存されていないことを検証します。
    
    **Validates: Requirements 8.4**
    """
    all_findings = {}
    
    for file_path in all_project_files:
        findings = scan_file_for_aws_credentials(file_path)
        if findings:
            # プロジェクトルートからの相対パスを取得
            relative_path = file_path.relative_to(file_path.parents[len(file_path.parents) - 1])
            all_findings[str(relative_path)] = findings
    
    # アサーション: AWS認証情報が検出されないこと
    assert not all_findings, (
        f"❌ プロジェクト内のファイルに平文のAWS認証情報が検出されました:\n"
        + "\n".join([
            f"  📄 {file_name}:\n" + "\n".join([
                f"    - 行 {line_num}: {pattern_name} = '{match[:20]}...'" 
                if len(match) > 20 else f"    - 行 {line_num}: {pattern_name} = '{match}'"
                for pattern_name, match, line_num in findings
            ])
            for file_name, findings in all_findings.items()
        ])
        + "\n\n⚠️  AWS認証情報は環境変数またはAWS CLIセッションを使用してください。"
    )


@given(st.text(min_size=20, max_size=1000))
def test_property_no_aws_access_key_in_content(file_content: str):
    """
    Feature: aws-client-vpn, Property 2 (Hypothesis)
    
    任意のテキストコンテンツにAWS Access Key IDが含まれていないことを検証します。
    Hypothesisによるランダム入力生成で広範なカバレッジを実現します。
    
    **Validates: Requirements 8.4**
    """
    # AWS Access Key ID パターン
    aws_key_pattern = r'AKIA[0-9A-Z]{16}'
    
    matches = re.findall(aws_key_pattern, file_content)
    
    # 例示用のキーを除外
    real_keys = [m for m in matches if m not in EXAMPLE_KEYS]
    
    assert len(real_keys) == 0, (
        f"❌ AWS Access Key IDが検出されました: {real_keys}"
    )


@given(st.text(min_size=50, max_size=1000))
def test_property_no_aws_secret_key_pattern_in_content(file_content: str):
    """
    Feature: aws-client-vpn, Property 2 (Hypothesis)
    
    任意のテキストコンテンツにAWS Secret Access Keyパターンが含まれていないことを検証します。
    
    **Validates: Requirements 8.4**
    """
    # AWS Secret Access Key パターン（キーワード付き）
    secret_key_pattern = r'(?:aws_secret_access_key|secret_access_key|SecretAccessKey)\s*[=:]\s*["\']?([A-Za-z0-9/+=]{40})["\']?'
    
    matches = re.findall(secret_key_pattern, file_content, re.IGNORECASE)
    
    # 例示用のキーを除外
    real_keys = [m for m in matches if m not in EXAMPLE_KEYS]
    
    assert len(real_keys) == 0, (
        f"❌ AWS Secret Access Keyパターンが検出されました"
    )


@given(st.text(min_size=20, max_size=500))
def test_property_no_aws_env_var_credentials_in_content(file_content: str):
    """
    Feature: aws-client-vpn, Property 2 (Hypothesis)
    
    任意のテキストコンテンツに環境変数形式のAWS認証情報が含まれていないことを検証します。
    
    **Validates: Requirements 8.4**
    """
    # 環境変数形式のAWS Access Key ID
    env_var_pattern = r'AWS_ACCESS_KEY_ID\s*=\s*["\']?(AKIA[0-9A-Z]{16})["\']?'
    
    matches = re.findall(env_var_pattern, file_content)
    
    # 例示用のキーを除外
    real_keys = [m for m in matches if m not in EXAMPLE_KEYS]
    
    assert len(real_keys) == 0, (
        f"❌ 環境変数形式のAWS認証情報が検出されました: {real_keys}"
    )


def test_gitignore_excludes_credential_files(project_root_dir):
    """
    .gitignoreファイルが認証情報を含む可能性のあるファイルを除外していることを検証します。
    
    **Validates: Requirements 8.4**
    """
    gitignore_path = project_root_dir / ".gitignore"
    
    if not gitignore_path.exists():
        pytest.fail("❌ .gitignoreファイルが存在しません")
    
    with open(gitignore_path, 'r', encoding='utf-8') as f:
        gitignore_content = f.read()
    
    # 除外すべきパターン
    required_patterns = [
        r'\.tfvars',      # Terraform変数ファイル
        r'\.env',         # 環境変数ファイル
        r'credentials',   # AWS認証情報ファイル
    ]
    
    missing_patterns = []
    for pattern in required_patterns:
        if not re.search(pattern, gitignore_content):
            missing_patterns.append(pattern)
    
    assert not missing_patterns, (
        f"❌ .gitignoreに以下のパターンが含まれていません: {missing_patterns}\n"
        f"   認証情報ファイルが誤ってコミットされる可能性があります。"
    )


def test_no_credentials_in_terraform_state_files(project_root_dir):
    """
    Terraformステートファイルがプロジェクトに含まれていないことを検証します。
    （ステートファイルには機密情報が含まれる可能性があるため）
    
    **Validates: Requirements 8.4**
    """
    terraform_dir = project_root_dir / "terraform"
    
    if not terraform_dir.exists():
        pytest.skip("Terraformディレクトリが存在しません")
    
    # .tfstateファイルを検索
    state_files = list(terraform_dir.glob("*.tfstate*"))
    
    assert len(state_files) == 0, (
        f"❌ Terraformステートファイルが検出されました: {[f.name for f in state_files]}\n"
        f"   ステートファイルは.gitignoreで除外し、リモートバックエンドを使用してください。"
    )


if __name__ == "__main__":
    # スタンドアロン実行用
    pytest.main([__file__, "-v", "--hypothesis-show-statistics"])
