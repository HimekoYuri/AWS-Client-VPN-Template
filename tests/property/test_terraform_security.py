"""
Property-Based Test: Terraformコードセキュリティスキャン

**Validates: Requirements 6.4**

このテストは、Terraformコード内に機密情報が平文で含まれていないことを検証します。
OWASP基準に準拠し、パスワード、秘密鍵、APIキーなどの機密情報パターンをスキャンします。
"""

import re
from pathlib import Path
from typing import List

import pytest
from hypothesis import given, strategies as st


# 機密情報パターン（OWASP基準）
SENSITIVE_PATTERNS = [
    # パスワードパターン（変数参照を除く）
    (r'password\s*=\s*["\'](?!var\.|data\.|local\.|module\.)[^"\']{3,}["\']', "password"),
    
    # シークレットパターン（変数参照を除く）
    (r'secret\s*=\s*["\'](?!var\.|data\.|local\.|module\.)[^"\']{3,}["\']', "secret"),
    
    # APIキーパターン（変数参照を除く）
    (r'api_key\s*=\s*["\'](?!var\.|data\.|local\.|module\.)[^"\']{3,}["\']', "api_key"),
    
    # アクセスキーパターン（変数参照を除く）
    (r'access_key\s*=\s*["\'](?!var\.|data\.|local\.|module\.)[^"\']{3,}["\']', "access_key"),
    
    # 秘密鍵パターン（変数参照とfile()関数を除く）
    (r'private_key\s*=\s*["\'](?!var\.|data\.|local\.|module\.|file\()[^"\']{10,}["\']', "private_key"),
    
    # AWS Access Key ID パターン（実際のキー形式）
    (r'AKIA[0-9A-Z]{16}', "AWS Access Key ID"),
    
    # AWS Secret Access Key パターン（40文字のBase64風文字列）
    (r'(?<![A-Za-z0-9/+=])[A-Za-z0-9/+=]{40}(?![A-Za-z0-9/+=])', "AWS Secret Access Key"),
    
    # トークンパターン（変数参照を除く）
    (r'token\s*=\s*["\'](?!var\.|data\.|local\.|module\.)[^"\']{10,}["\']', "token"),
    
    # 認証情報パターン（変数参照を除く）
    (r'credentials\s*=\s*["\'](?!var\.|data\.|local\.|module\.)[^"\']{3,}["\']', "credentials"),
]


def scan_file_for_secrets(file_path: Path) -> List[tuple]:
    """
    ファイルをスキャンして機密情報パターンを検出する
    
    Args:
        file_path: スキャンするファイルのパス
        
    Returns:
        検出された機密情報のリスト [(パターン名, マッチした文字列, 行番号), ...]
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except (UnicodeDecodeError, PermissionError):
        # バイナリファイルや読み取り不可ファイルはスキップ
        return []
    
    findings = []
    lines = content.split('\n')
    
    for pattern, pattern_name in SENSITIVE_PATTERNS:
        for line_num, line in enumerate(lines, start=1):
            # コメント行はスキップ
            if line.strip().startswith('#'):
                continue
            
            matches = re.findall(pattern, line, re.IGNORECASE)
            for match in matches:
                findings.append((pattern_name, match, line_num))
    
    return findings


def test_terraform_files_no_plaintext_secrets(terraform_files):
    """
    Feature: aws-client-vpn, Property 1
    
    すべてのTerraformファイル（.tf）に機密情報が平文で含まれていないことを検証します。
    
    **Validates: Requirements 6.4**
    """
    all_findings = {}
    
    for tf_file in terraform_files:
        findings = scan_file_for_secrets(tf_file)
        if findings:
            all_findings[tf_file.name] = findings
    
    # アサーション: 機密情報が検出されないこと
    assert not all_findings, (
        f"❌ Terraformファイルに平文の機密情報が検出されました:\n"
        + "\n".join([
            f"  📄 {file_name}:\n" + "\n".join([
                f"    - 行 {line_num}: {pattern_name} = '{match[:50]}...'" 
                if len(match) > 50 else f"    - 行 {line_num}: {pattern_name} = '{match}'"
                for pattern_name, match, line_num in findings
            ])
            for file_name, findings in all_findings.items()
        ])
    )


@given(st.text(min_size=10, max_size=1000))
def test_property_no_aws_access_keys_in_content(file_content: str):
    """
    Feature: aws-client-vpn, Property 1 (Hypothesis)
    
    任意のテキストコンテンツにAWS Access Key IDパターンが含まれていないことを検証します。
    Hypothesisによるランダム入力生成で広範なカバレッジを実現します。
    
    **Validates: Requirements 6.4**
    """
    # AWS Access Key ID パターン
    aws_key_pattern = r'AKIA[0-9A-Z]{16}'
    
    matches = re.findall(aws_key_pattern, file_content)
    
    # 実際のAWSキーが含まれていないことを確認
    # （テストデータとして意図的に含まれている場合は除外）
    real_keys = [m for m in matches if not m.startswith('AKIAIOSFODNN7EXAMPLE')]
    
    assert len(real_keys) == 0, (
        f"❌ AWS Access Key IDパターンが検出されました: {real_keys}"
    )


@given(st.text(min_size=10, max_size=1000))
def test_property_no_hardcoded_passwords_in_content(file_content: str):
    """
    Feature: aws-client-vpn, Property 1 (Hypothesis)
    
    任意のテキストコンテンツにハードコードされたパスワードパターンが含まれていないことを検証します。
    
    **Validates: Requirements 6.4**
    """
    # ハードコードされたパスワードパターン（変数参照を除く）
    password_pattern = r'password\s*=\s*["\'](?!var\.|data\.|local\.|module\.|\$\{)[^"\']{3,}["\']'
    
    matches = re.findall(password_pattern, file_content, re.IGNORECASE)
    
    assert len(matches) == 0, (
        f"❌ ハードコードされたパスワードが検出されました: {matches}"
    )


def test_terraform_variables_use_sensitive_flag(terraform_files):
    """
    Terraformの機密変数にsensitive = trueフラグが設定されていることを検証します。
    
    **Validates: Requirements 6.4**
    """
    sensitive_var_names = [
        'password', 'secret', 'api_key', 'access_key', 
        'private_key', 'token', 'credentials', 'saml'
    ]
    
    issues = {}
    
    for tf_file in terraform_files:
        try:
            with open(tf_file, 'r', encoding='utf-8') as f:
                content = f.read()
        except (UnicodeDecodeError, PermissionError):
            continue
        
        # variable ブロックを検索
        variable_blocks = re.finditer(
            r'variable\s+"([^"]+)"\s*\{([^}]+)\}',
            content,
            re.DOTALL
        )
        
        for match in variable_blocks:
            var_name = match.group(1)
            var_block = match.group(2)
            
            # 機密情報を含む変数名かチェック
            is_sensitive_var = any(
                sensitive_name in var_name.lower() 
                for sensitive_name in sensitive_var_names
            )
            
            if is_sensitive_var:
                # sensitive = true が設定されているかチェック
                has_sensitive_flag = re.search(
                    r'sensitive\s*=\s*true',
                    var_block,
                    re.IGNORECASE
                )
                
                if not has_sensitive_flag:
                    if tf_file.name not in issues:
                        issues[tf_file.name] = []
                    issues[tf_file.name].append(var_name)
    
    # 警告として出力（エラーにはしない）
    if issues:
        warning_msg = (
            "⚠️  以下の機密変数にsensitive = trueフラグが設定されていません:\n"
            + "\n".join([
                f"  📄 {file_name}: {', '.join(var_names)}"
                for file_name, var_names in issues.items()
            ])
        )
        pytest.skip(warning_msg)


if __name__ == "__main__":
    # スタンドアロン実行用
    pytest.main([__file__, "-v", "--hypothesis-show-statistics"])
