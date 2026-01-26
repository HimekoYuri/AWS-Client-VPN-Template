# -*- coding: utf-8 -*-
"""
ネットワーク構成の検証テスト

Requirements: 5.1, 5.2, 5.4, 5.5
VPC、サブネット、Internet Gateway、NAT Gatewayが正しく作成されることを検証します。
"""

import pytest


class TestVPCConfiguration:
    """VPC構成の検証テスト"""

    def test_vpc_exists(self, ec2_client, vpc_name):
        """
        Requirements 5.1: VPCが作成されていることを検証
        """
        vpcs = ec2_client.describe_vpcs(
            Filters=[{"Name": "tag:Name", "Values": [vpc_name]}]
        )
        
        assert len(vpcs["Vpcs"]) == 1, f"VPCが見つかりません: {vpc_name}"

    def test_vpc_cidr_block(self, ec2_client, vpc_name, expected_vpc_cidr):
        """
        Requirements 5.1: VPCが正しいCIDRブロックで作成されていることを検証
        """
        vpcs = ec2_client.describe_vpcs(
            Filters=[{"Name": "tag:Name", "Values": [vpc_name]}]
        )
        
        assert len(vpcs["Vpcs"]) == 1
        actual_cidr = vpcs["Vpcs"][0]["CidrBlock"]
        assert actual_cidr == expected_vpc_cidr, \
            f"VPC CIDRが期待値と異なります。期待: {expected_vpc_cidr}, 実際: {actual_cidr}"

    def test_vpc_dns_settings(self, ec2_client, vpc_name):
        """
        Requirements 5.1: VPCのDNS設定が有効化されていることを検証
        """
        vpcs = ec2_client.describe_vpcs(
            Filters=[{"Name": "tag:Name", "Values": [vpc_name]}]
        )
        
        assert len(vpcs["Vpcs"]) == 1
        vpc = vpcs["Vpcs"][0]
        
        assert vpc["EnableDnsHostnames"] is True, "DNS Hostnamesが有効化されていません"
        assert vpc["EnableDnsSupport"] is True, "DNS Supportが有効化されていません"


class TestSubnetConfiguration:
    """サブネット構成の検証テスト"""

    def test_public_subnets_exist(self, ec2_client, expected_public_subnet_cidrs):
        """
        Requirements 5.2: パブリックサブネットが作成されていることを検証
        """
        subnets = ec2_client.describe_subnets(
            Filters=[{"Name": "tag:Type", "Values": ["Public"]}]
        )
        
        assert len(subnets["Subnets"]) == len(expected_public_subnet_cidrs), \
            f"パブリックサブネット数が期待値と異なります。期待: {len(expected_public_subnet_cidrs)}, 実際: {len(subnets['Subnets'])}"

    def test_public_subnet_cidrs(self, ec2_client, expected_public_subnet_cidrs):
        """
        Requirements 5.2: パブリックサブネットが正しいCIDRブロックで作成されていることを検証
        """
        subnets = ec2_client.describe_subnets(
            Filters=[{"Name": "tag:Type", "Values": ["Public"]}]
        )
        
        actual_cidrs = sorted([subnet["CidrBlock"] for subnet in subnets["Subnets"]])
        expected_cidrs = sorted(expected_public_subnet_cidrs)
        
        assert actual_cidrs == expected_cidrs, \
            f"パブリックサブネットCIDRが期待値と異なります。期待: {expected_cidrs}, 実際: {actual_cidrs}"

    def test_public_subnets_multi_az(self, ec2_client, expected_availability_zones):
        """
        Requirements 5.2: パブリックサブネットがMulti-AZ構成であることを検証
        """
        subnets = ec2_client.describe_subnets(
            Filters=[{"Name": "tag:Type", "Values": ["Public"]}]
        )
        
        actual_azs = sorted([subnet["AvailabilityZone"] for subnet in subnets["Subnets"]])
        expected_azs = sorted(expected_availability_zones)
        
        assert actual_azs == expected_azs, \
            f"パブリックサブネットのAZが期待値と異なります。期待: {expected_azs}, 実際: {actual_azs}"

    def test_private_subnets_exist(self, ec2_client, expected_private_subnet_cidrs):
        """
        Requirements 5.2: プライベートサブネットが作成されていることを検証
        """
        subnets = ec2_client.describe_subnets(
            Filters=[{"Name": "tag:Type", "Values": ["Private"]}]
        )
        
        assert len(subnets["Subnets"]) == len(expected_private_subnet_cidrs), \
            f"プライベートサブネット数が期待値と異なります。期待: {len(expected_private_subnet_cidrs)}, 実際: {len(subnets['Subnets'])}"

    def test_private_subnet_cidrs(self, ec2_client, expected_private_subnet_cidrs):
        """
        Requirements 5.2: プライベートサブネットが正しいCIDRブロックで作成されていることを検証
        """
        subnets = ec2_client.describe_subnets(
            Filters=[{"Name": "tag:Type", "Values": ["Private"]}]
        )
        
        actual_cidrs = sorted([subnet["CidrBlock"] for subnet in subnets["Subnets"]])
        expected_cidrs = sorted(expected_private_subnet_cidrs)
        
        assert actual_cidrs == expected_cidrs, \
            f"プライベートサブネットCIDRが期待値と異なります。期待: {expected_cidrs}, 実際: {actual_cidrs}"

    def test_private_subnets_multi_az(self, ec2_client, expected_availability_zones):
        """
        Requirements 5.2: プライベートサブネットがMulti-AZ構成であることを検証
        """
        subnets = ec2_client.describe_subnets(
            Filters=[{"Name": "tag:Type", "Values": ["Private"]}]
        )
        
        actual_azs = sorted([subnet["AvailabilityZone"] for subnet in subnets["Subnets"]])
        expected_azs = sorted(expected_availability_zones)
        
        assert actual_azs == expected_azs, \
            f"プライベートサブネットのAZが期待値と異なります。期待: {expected_azs}, 実際: {actual_azs}"


class TestInternetGateway:
    """Internet Gateway構成の検証テスト"""

    def test_internet_gateway_exists(self, ec2_client, vpc_name):
        """
        Requirements 5.4: Internet GatewayがVPCにアタッチされていることを検証
        """
        # VPC IDを取得
        vpcs = ec2_client.describe_vpcs(
            Filters=[{"Name": "tag:Name", "Values": [vpc_name]}]
        )
        assert len(vpcs["Vpcs"]) == 1
        vpc_id = vpcs["Vpcs"][0]["VpcId"]

        # Internet Gatewayを取得
        igws = ec2_client.describe_internet_gateways(
            Filters=[
                {"Name": "attachment.vpc-id", "Values": [vpc_id]},
                {"Name": "tag:Name", "Values": ["client-vpn-igw"]}
            ]
        )
        
        assert len(igws["InternetGateways"]) == 1, \
            "Internet GatewayがVPCにアタッチされていません"
        
        # アタッチメント状態を確認
        igw = igws["InternetGateways"][0]
        assert len(igw["Attachments"]) == 1, "Internet Gatewayのアタッチメントが見つかりません"
        assert igw["Attachments"][0]["State"] == "available", \
            f"Internet Gatewayのアタッチメント状態が不正です: {igw['Attachments'][0]['State']}"


class TestNATGateway:
    """NAT Gateway構成の検証テスト"""

    def test_nat_gateway_exists(self, ec2_client):
        """
        Requirements 5.5: NAT Gatewayがパブリックサブネットに配置されていることを検証
        """
        nat_gateways = ec2_client.describe_nat_gateways(
            Filters=[
                {"Name": "tag:Name", "Values": ["client-vpn-nat-gateway"]},
                {"Name": "state", "Values": ["available"]}
            ]
        )
        
        assert len(nat_gateways["NatGateways"]) >= 1, \
            "NAT Gatewayが見つかりません"

    def test_nat_gateway_in_public_subnet(self, ec2_client):
        """
        Requirements 5.5: NAT Gatewayがパブリックサブネットに配置されていることを検証
        """
        # パブリックサブネットIDを取得
        public_subnets = ec2_client.describe_subnets(
            Filters=[{"Name": "tag:Type", "Values": ["Public"]}]
        )
        public_subnet_ids = [subnet["SubnetId"] for subnet in public_subnets["Subnets"]]
        
        # NAT Gatewayを取得
        nat_gateways = ec2_client.describe_nat_gateways(
            Filters=[
                {"Name": "tag:Name", "Values": ["client-vpn-nat-gateway"]},
                {"Name": "state", "Values": ["available"]}
            ]
        )
        
        assert len(nat_gateways["NatGateways"]) >= 1
        nat_gateway = nat_gateways["NatGateways"][0]
        
        assert nat_gateway["SubnetId"] in public_subnet_ids, \
            f"NAT Gatewayがパブリックサブネットに配置されていません。SubnetId: {nat_gateway['SubnetId']}"


    def test_nat_gateway_has_elastic_ip(self, ec2_client):
        """
        Requirements 4.2, 5.5: NAT GatewayにElastic IPが割り当てられていることを検証
        """
        nat_gateways = ec2_client.describe_nat_gateways(
            Filters=[
                {"Name": "tag:Name", "Values": ["client-vpn-nat-gateway"]},
                {"Name": "state", "Values": ["available"]}
            ]
        )
        
        assert len(nat_gateways["NatGateways"]) >= 1
        nat_gateway = nat_gateways["NatGateways"][0]
        
        # NAT GatewayアドレスにElastic IPが割り当てられていることを確認
        assert len(nat_gateway["NatGatewayAddresses"]) >= 1, \
            "NAT Gatewayにアドレスが割り当てられていません"
        
        nat_address = nat_gateway["NatGatewayAddresses"][0]
        assert "AllocationId" in nat_address, \
            "NAT GatewayにElastic IPが割り当てられていません"
        assert "PublicIp" in nat_address, \
            "NAT GatewayにパブリックIPが割り当てられていません"

    def test_elastic_ip_exists(self, ec2_client):
        """
        Requirements 4.2: Elastic IPが作成されていることを検証
        """
        eips = ec2_client.describe_addresses(
            Filters=[{"Name": "tag:Name", "Values": ["client-vpn-nat-eip"]}]
        )
        
        assert len(eips["Addresses"]) == 1, \
            "Elastic IPが見つかりません"
        
        eip = eips["Addresses"][0]
        assert "PublicIp" in eip, "Elastic IPにパブリックIPが割り当てられていません"
        assert eip["Domain"] == "vpc", f"Elastic IPのドメインが不正です: {eip['Domain']}"


class TestRouteTables:
    """ルートテーブル構成の検証テスト"""

    def test_public_route_table_exists(self, ec2_client):
        """
        Requirements 4.5: パブリックサブネット用ルートテーブルが存在することを検証
        """
        route_tables = ec2_client.describe_route_tables(
            Filters=[
                {"Name": "tag:Name", "Values": ["client-vpn-public-rt"]},
                {"Name": "tag:Type", "Values": ["Public"]}
            ]
        )
        
        assert len(route_tables["RouteTables"]) == 1, \
            "パブリックルートテーブルが見つかりません"


    def test_public_route_to_internet_gateway(self, ec2_client, vpc_name):
        """
        Requirements 4.5: パブリックルートテーブルにInternet Gatewayへのルートが設定されていることを検証
        """
        # VPC IDを取得
        vpcs = ec2_client.describe_vpcs(
            Filters=[{"Name": "tag:Name", "Values": [vpc_name]}]
        )
        vpc_id = vpcs["Vpcs"][0]["VpcId"]
        
        # Internet Gateway IDを取得
        igws = ec2_client.describe_internet_gateways(
            Filters=[
                {"Name": "attachment.vpc-id", "Values": [vpc_id]},
                {"Name": "tag:Name", "Values": ["client-vpn-igw"]}
            ]
        )
        igw_id = igws["InternetGateways"][0]["InternetGatewayId"]
        
        # パブリックルートテーブルを取得
        route_tables = ec2_client.describe_route_tables(
            Filters=[{"Name": "tag:Name", "Values": ["client-vpn-public-rt"]}]
        )
        
        assert len(route_tables["RouteTables"]) == 1
        route_table = route_tables["RouteTables"][0]
        
        # 0.0.0.0/0へのルートがInternet Gatewayを指していることを確認
        routes = route_table["Routes"]
        igw_route = [r for r in routes if r.get("DestinationCidrBlock") == "0.0.0.0/0"]
        
        assert len(igw_route) == 1, \
            "パブリックルートテーブルに0.0.0.0/0へのルートが見つかりません"
        assert igw_route[0].get("GatewayId") == igw_id, \
            f"パブリックルートテーブルのルートがInternet Gatewayを指していません。期待: {igw_id}, 実際: {igw_route[0].get('GatewayId')}"

    def test_private_route_table_exists(self, ec2_client):
        """
        Requirements 4.1, 4.5: プライベートサブネット用ルートテーブルが存在することを検証
        """
        route_tables = ec2_client.describe_route_tables(
            Filters=[
                {"Name": "tag:Name", "Values": ["client-vpn-private-rt"]},
                {"Name": "tag:Type", "Values": ["Private"]}
            ]
        )
        
        assert len(route_tables["RouteTables"]) == 1, \
            "プライベートルートテーブルが見つかりません"

    def test_private_route_to_nat_gateway(self, ec2_client):
        """
        Requirements 4.1: プライベートルートテーブルにNAT Gatewayへのルートが設定されていることを検証
        """
        # NAT Gateway IDを取得
        nat_gateways = ec2_client.describe_nat_gateways(
            Filters=[
                {"Name": "tag:Name", "Values": ["client-vpn-nat-gateway"]},
                {"Name": "state", "Values": ["available"]}
            ]
        )
        assert len(nat_gateways["NatGateways"]) >= 1
        nat_gateway_id = nat_gateways["NatGateways"][0]["NatGatewayId"]

        
        # プライベートルートテーブルを取得
        route_tables = ec2_client.describe_route_tables(
            Filters=[{"Name": "tag:Name", "Values": ["client-vpn-private-rt"]}]
        )
        
        assert len(route_tables["RouteTables"]) == 1
        route_table = route_tables["RouteTables"][0]
        
        # 0.0.0.0/0へのルートがNAT Gatewayを指していることを確認
        routes = route_table["Routes"]
        nat_route = [r for r in routes if r.get("DestinationCidrBlock") == "0.0.0.0/0"]
        
        assert len(nat_route) == 1, \
            "プライベートルートテーブルに0.0.0.0/0へのルートが見つかりません"
        assert nat_route[0].get("NatGatewayId") == nat_gateway_id, \
            f"プライベートルートテーブルのルートがNAT Gatewayを指していません。期待: {nat_gateway_id}, 実際: {nat_route[0].get('NatGatewayId')}"

    def test_public_subnets_associated_with_public_route_table(self, ec2_client):
        """
        Requirements 4.5: パブリックサブネットがパブリックルートテーブルに関連付けられていることを検証
        """
        # パブリックサブネットIDを取得
        public_subnets = ec2_client.describe_subnets(
            Filters=[{"Name": "tag:Type", "Values": ["Public"]}]
        )
        public_subnet_ids = {subnet["SubnetId"] for subnet in public_subnets["Subnets"]}
        
        # パブリックルートテーブルを取得
        route_tables = ec2_client.describe_route_tables(
            Filters=[{"Name": "tag:Name", "Values": ["client-vpn-public-rt"]}]
        )
        
        assert len(route_tables["RouteTables"]) == 1
        route_table = route_tables["RouteTables"][0]
        
        # 関連付けられているサブネットIDを取得
        associations = route_table.get("Associations", [])
        associated_subnet_ids = {
            assoc["SubnetId"] for assoc in associations if "SubnetId" in assoc
        }
        
        assert public_subnet_ids == associated_subnet_ids, \
            f"パブリックサブネットがパブリックルートテーブルに正しく関連付けられていません。期待: {public_subnet_ids}, 実際: {associated_subnet_ids}"

    def test_private_subnets_associated_with_private_route_table(self, ec2_client):
        """
        Requirements 4.1: プライベートサブネットがプライベートルートテーブルに関連付けられていることを検証
        """
        # プライベートサブネットIDを取得
        private_subnets = ec2_client.describe_subnets(
            Filters=[{"Name": "tag:Type", "Values": ["Private"]}]
        )
        private_subnet_ids = {subnet["SubnetId"] for subnet in private_subnets["Subnets"]}
        
        # プライベートルートテーブルを取得
        route_tables = ec2_client.describe_route_tables(
            Filters=[{"Name": "tag:Name", "Values": ["client-vpn-private-rt"]}]
        )
        
        assert len(route_tables["RouteTables"]) == 1
        route_table = route_tables["RouteTables"][0]
        
        # 関連付けられているサブネットIDを取得
        associations = route_table.get("Associations", [])
        associated_subnet_ids = {
            assoc["SubnetId"] for assoc in associations if "SubnetId" in assoc
        }
        
        assert private_subnet_ids == associated_subnet_ids, \
            f"プライベートサブネットがプライベートルートテーブルに正しく関連付けられていません。期待: {private_subnet_ids}, 実際: {associated_subnet_ids}"
