# -*- coding: utf-8 -*-
"""
統合テスト用の共通設定とフィクスチャ

このファイルは、pytest統合テストで使用する共通設定とフィクスチャを提供します。
AWS boto3クライアントの初期化、テスト環境の設定などを行います。
"""

import boto3
import pytest
import os


@pytest.fixture(scope="session")
def aws_region():
    """AWSリージョンを返すフィクスチャ"""
    return os.environ.get("AWS_REGION", "ap-northeast-1")


@pytest.fixture(scope="session")
def ec2_client(aws_region):
    """EC2クライアントを返すフィクスチャ"""
    return boto3.client("ec2", region_name=aws_region)


@pytest.fixture(scope="session")
def logs_client(aws_region):
    """CloudWatch Logsクライアントを返すフィクスチャ"""
    return boto3.client("logs", region_name=aws_region)


@pytest.fixture(scope="session")
def cloudtrail_client(aws_region):
    """CloudTrailクライアントを返すフィクスチャ"""
    return boto3.client("cloudtrail", region_name=aws_region)


@pytest.fixture(scope="session")
def acm_client(aws_region):
    """AWS Certificate Managerクライアントを返すフィクスチャ"""
    return boto3.client("acm", region_name=aws_region)


@pytest.fixture(scope="session")
def iam_client(aws_region):
    """IAMクライアントを返すフィクスチャ"""
    return boto3.client("iam", region_name=aws_region)


@pytest.fixture(scope="session")
def s3_client(aws_region):
    """S3クライアントを返すフィクスチャ"""
    return boto3.client("s3", region_name=aws_region)


@pytest.fixture(scope="session")
def sts_client(aws_region):
    """STSクライアントを返すフィクスチャ（アカウントID取得用）"""
    return boto3.client("sts", region_name=aws_region)


@pytest.fixture(scope="session")
def vpc_name():
    """VPC名を返すフィクスチャ"""
    return "client-vpn-vpc"


@pytest.fixture(scope="session")
def expected_vpc_cidr():
    """期待されるVPC CIDRブロックを返すフィクスチャ"""
    return "192.168.0.0/16"


@pytest.fixture(scope="session")
def expected_public_subnet_cidrs():
    """期待されるパブリックサブネットCIDRブロックを返すフィクスチャ"""
    return ["192.168.1.0/24", "192.168.2.0/24"]


@pytest.fixture(scope="session")
def expected_private_subnet_cidrs():
    """期待されるプライベートサブネットCIDRブロックを返すフィクスチャ"""
    return ["192.168.10.0/24", "192.168.11.0/24"]


@pytest.fixture(scope="session")
def expected_availability_zones():
    """期待されるアベイラビリティゾーンを返すフィクスチャ"""
    return ["ap-northeast-1a", "ap-northeast-1c"]
