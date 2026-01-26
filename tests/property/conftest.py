# Property-Based Testing Configuration
# プロパティベーステストの共通設定

import os
import sys
from pathlib import Path

import pytest
from hypothesis import settings, Verbosity

# プロジェクトルートをPythonパスに追加
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# Hypothesisの設定
settings.register_profile("default", max_examples=100, verbosity=Verbosity.normal)
settings.register_profile("ci", max_examples=200, verbosity=Verbosity.verbose)
settings.register_profile("dev", max_examples=50, verbosity=Verbosity.verbose)

# 環境変数からプロファイルを選択（デフォルトは"default"）
profile = os.getenv("HYPOTHESIS_PROFILE", "default")
settings.load_profile(profile)


@pytest.fixture(scope="session")
def terraform_dir():
    """Terraformディレクトリのパスを返す"""
    return project_root / "terraform"


@pytest.fixture(scope="session")
def project_root_dir():
    """プロジェクトルートディレクトリのパスを返す"""
    return project_root


@pytest.fixture(scope="session")
def terraform_files(terraform_dir):
    """すべてのTerraformファイル（.tf）のリストを返す"""
    return list(terraform_dir.glob("*.tf"))


@pytest.fixture(scope="session")
def all_project_files(project_root_dir):
    """プロジェクト内のすべてのファイルのリストを返す（バイナリファイルを除く）"""
    exclude_dirs = {".git", "node_modules", "__pycache__", ".terraform", ".venv", "venv"}
    exclude_extensions = {".pyc", ".pyo", ".so", ".dll", ".exe", ".bin", ".jpg", ".png", ".gif"}
    
    files = []
    for file_path in project_root_dir.rglob("*"):
        if file_path.is_file():
            # 除外ディレクトリをチェック
            if any(excluded in file_path.parts for excluded in exclude_dirs):
                continue
            # 除外拡張子をチェック
            if file_path.suffix in exclude_extensions:
                continue
            files.append(file_path)
    
    return files
