# -*- coding: utf-8 -*-
"""
セキュリティグループの検証テスト

Requirements: 5.6, 7.3
Client VPNエンドポイント用セキュリティグループが正しく設定されていることを検証します。
"""

import pytest


class TestVPNEndpointSecurityGroup:
    """Client VPNエンドポイント用セキュリティグループの検証テスト"""

    def test_security_group_exists(self, ec2_client):
        """
        Requirements 5.6: Client VPNエンドポイント用セキュリティグループが存在することを検証
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1, \
            "Client VPNエンドポイント用セキュリティグループが見つかりません"

    def test_security_group_description(self, ec2_client):
        """
        Requirements 5.6: セキュリティグループに適切な説明が設定されていることを検証
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        assert sg["Description"], "セキュリティグループに説明が設定されていません"
        assert "Client VPN" in sg["Description"], \
            f"セキュリティグループの説明が不適切です: {sg['Description']}"

    def test_security_group_vpc_association(self, ec2_client, vpc_name):
        """
        Requirements 5.6: セキュリティグループが正しいVPCに関連付けられていることを検証
        """
        # VPC IDを取得
        vpcs = ec2_client.describe_vpcs(
            Filters=[{"Name": "tag:Name", "Values": [vpc_name]}]
        )
        assert len(vpcs["Vpcs"]) == 1
        vpc_id = vpcs["Vpcs"][0]["VpcId"]
        
        # セキュリティグループを取得
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        assert sg["VpcId"] == vpc_id, \
            f"セキュリティグループが正しいVPCに関連付けられていません。期待: {vpc_id}, 実際: {sg['VpcId']}"

    def test_security_group_tags(self, ec2_client):
        """
        Requirements 5.6: セキュリティグループに適切なタグが設定されていることを検証
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        tags = {tag["Key"]: tag["Value"] for tag in sg.get("Tags", [])}
        
        # 必須タグの確認
        assert "Name" in tags, "Nameタグが設定されていません"
        assert tags["Name"] == "client-vpn-endpoint-sg", \
            f"Nameタグの値が不正です: {tags['Name']}"
        
        assert "Environment" in tags, "Environmentタグが設定されていません"
        assert "ManagedBy" in tags, "ManagedByタグが設定されていません"
        assert tags["ManagedBy"] == "terraform", \
            f"ManagedByタグの値が不正です: {tags['ManagedBy']}"


class TestSecurityGroupIngressRules:
    """セキュリティグループのインバウンドルール検証テスト"""

    def test_ingress_rules_count(self, ec2_client):
        """
        Requirements 7.3: インバウンドルールが最小限（UDP 443のみ）であることを検証
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        ingress_rules = sg["IpPermissions"]
        assert len(ingress_rules) == 1, \
            f"インバウンドルールが複数設定されています。期待: 1, 実際: {len(ingress_rules)}"

    def test_ingress_udp_443_allowed(self, ec2_client):
        """
        Requirements 7.3: UDP 443のインバウンドトラフィックが許可されていることを検証
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        ingress_rules = sg["IpPermissions"]
        assert len(ingress_rules) == 1
        
        rule = ingress_rules[0]
        
        # プロトコルの確認（UDPは17）
        assert rule["IpProtocol"] == "udp", \
            f"プロトコルがUDPではありません: {rule['IpProtocol']}"
        
        # ポート番号の確認
        assert rule["FromPort"] == 443, \
            f"FromPortが443ではありません: {rule['FromPort']}"
        assert rule["ToPort"] == 443, \
            f"ToPortが443ではありません: {rule['ToPort']}"

    def test_ingress_source_cidr(self, ec2_client):
        """
        Requirements 7.3: インバウンドルールのソースCIDRが0.0.0.0/0であることを検証
        （Client VPNの性質上、任意の場所からの接続を受け入れる必要がある）
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        ingress_rules = sg["IpPermissions"]
        assert len(ingress_rules) == 1
        
        rule = ingress_rules[0]
        
        # IPv4 CIDRの確認
        ipv4_ranges = rule.get("IpRanges", [])
        assert len(ipv4_ranges) >= 1, "IPv4 CIDRが設定されていません"
        
        cidrs = [ip_range["CidrIp"] for ip_range in ipv4_ranges]
        assert "0.0.0.0/0" in cidrs, \
            f"0.0.0.0/0が許可されていません。実際: {cidrs}"

    def test_no_ssh_rdp_ports_open(self, ec2_client):
        """
        Requirements 7.3: SSH（22）やRDP（3389）などの管理ポートが開放されていないことを検証
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        ingress_rules = sg["IpPermissions"]
        
        # 危険なポートのリスト
        dangerous_ports = [22, 3389, 3306, 5432, 1433, 27017]
        
        for rule in ingress_rules:
            from_port = rule.get("FromPort")
            to_port = rule.get("ToPort")
            
            if from_port is not None and to_port is not None:
                for dangerous_port in dangerous_ports:
                    assert not (from_port <= dangerous_port <= to_port), \
                        f"危険なポート {dangerous_port} が開放されています"


class TestSecurityGroupEgressRules:
    """セキュリティグループのアウトバウンドルール検証テスト"""

    def test_egress_rules_count(self, ec2_client):
        """
        Requirements 7.3: アウトバウンドルールが設定されていることを検証
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        egress_rules = sg["IpPermissionsEgress"]
        assert len(egress_rules) >= 1, \
            "アウトバウンドルールが設定されていません"

    def test_egress_all_traffic_allowed(self, ec2_client):
        """
        Requirements 7.3: 全アウトバウンドトラフィックが許可されていることを検証
        （VPN経由のインターネットアクセスに必要）
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        egress_rules = sg["IpPermissionsEgress"]
        
        # 全トラフィック許可ルールを検索
        all_traffic_rule = None
        for rule in egress_rules:
            if rule["IpProtocol"] == "-1":  # -1は全プロトコル
                all_traffic_rule = rule
                break
        
        assert all_traffic_rule is not None, \
            "全アウトバウンドトラフィックを許可するルールが見つかりません"
        
        # 宛先CIDRの確認
        ipv4_ranges = all_traffic_rule.get("IpRanges", [])
        assert len(ipv4_ranges) >= 1, "IPv4 CIDRが設定されていません"
        
        cidrs = [ip_range["CidrIp"] for ip_range in ipv4_ranges]
        assert "0.0.0.0/0" in cidrs, \
            f"0.0.0.0/0への全トラフィックが許可されていません。実際: {cidrs}"


class TestSecurityGroupOWASPCompliance:
    """OWASP基準準拠の検証テスト"""

    def test_least_privilege_principle(self, ec2_client):
        """
        OWASP準拠: 最小権限の原則が適用されていることを検証
        - インバウンド: UDP 443のみ
        - アウトバウンド: 全トラフィック（VPN用途で必要）
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        # インバウンドルールが1つのみであることを確認
        ingress_rules = sg["IpPermissions"]
        assert len(ingress_rules) == 1, \
            "インバウンドルールが最小限ではありません"
        
        # UDP 443のみが許可されていることを確認
        rule = ingress_rules[0]
        assert rule["IpProtocol"] == "udp", "プロトコルがUDPではありません"
        assert rule["FromPort"] == 443, "ポートが443ではありません"
        assert rule["ToPort"] == 443, "ポートが443ではありません"

    def test_default_deny_implicit(self, ec2_client):
        """
        OWASP準拠: デフォルト拒否が暗黙的に適用されていることを検証
        （AWSセキュリティグループはデフォルトで全インバウンドを拒否）
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        # 明示的に許可されたルールのみが存在することを確認
        ingress_rules = sg["IpPermissions"]
        
        # 全ポート開放（0-65535）のルールが存在しないことを確認
        for rule in ingress_rules:
            from_port = rule.get("FromPort", 0)
            to_port = rule.get("ToPort", 0)
            
            # 全ポート開放を検出
            is_all_ports = (from_port == 0 and to_port == 65535) or \
                          (from_port == 0 and to_port == 0 and rule["IpProtocol"] == "-1")
            
            assert not is_all_ports, \
                "全ポート開放のルールが存在します（デフォルト拒否の原則に違反）"

    def test_rule_descriptions_present(self, ec2_client):
        """
        OWASP準拠: すべてのルールに説明が付与されていることを検証
        （監査とトラブルシューティングのため）
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        # インバウンドルールの説明を確認
        ingress_rules = sg["IpPermissions"]
        for rule in ingress_rules:
            # IPv4範囲の説明を確認
            for ip_range in rule.get("IpRanges", []):
                description = ip_range.get("Description", "")
                assert description, \
                    f"インバウンドルールに説明が設定されていません: {rule}"
        
        # アウトバウンドルールの説明を確認
        egress_rules = sg["IpPermissionsEgress"]
        for rule in egress_rules:
            # IPv4範囲の説明を確認
            for ip_range in rule.get("IpRanges", []):
                description = ip_range.get("Description", "")
                assert description, \
                    f"アウトバウンドルールに説明が設定されていません: {rule}"


class TestSecurityGroupCISCompliance:
    """CIS AWS Foundations Benchmark準拠の検証テスト"""

    def test_security_group_has_description(self, ec2_client):
        """
        CIS 5.2: セキュリティグループに説明が設定されていることを検証
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        assert sg["Description"], \
            "セキュリティグループに説明が設定されていません（CIS 5.2違反）"
        
        # 説明が意味のある内容であることを確認（デフォルト値ではない）
        assert sg["Description"] != "Managed by Terraform", \
            "セキュリティグループの説明が汎用的すぎます"

    def test_no_unrestricted_ingress_on_all_ports(self, ec2_client):
        """
        CIS 5.1: 全ポート（0-65535）への無制限アクセスが許可されていないことを検証
        """
        security_groups = ec2_client.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": ["client-vpn-endpoint-sg"]}]
        )
        
        assert len(security_groups["SecurityGroups"]) == 1
        sg = security_groups["SecurityGroups"][0]
        
        ingress_rules = sg["IpPermissions"]
        
        for rule in ingress_rules:
            # 全プロトコル（-1）かつ0.0.0.0/0の組み合わせをチェック
            if rule["IpProtocol"] == "-1":
                for ip_range in rule.get("IpRanges", []):
                    assert ip_range["CidrIp"] != "0.0.0.0/0", \
                        "全ポート・全プロトコルへの無制限アクセスが許可されています（CIS 5.1違反）"
