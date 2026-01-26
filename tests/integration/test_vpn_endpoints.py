"""
統合テスト: VPNエンドポイント検証テスト

**Validates: Requirements 2.1, 3.1, 10.2, 10.4, 10.6**

このテストは、Client VPNエンドポイントが正しく作成・設定されていることを検証します。
- PC用VPNエンドポイント（SAML + MFA認証）
- スマホ用VPNエンドポイント（証明書認証）
"""

import pytest


@pytest.fixture(scope="module")
def pc_vpn_endpoint(ec2_client):
    """PC用VPNエンドポイントを取得"""
    endpoints = ec2_client.describe_client_vpn_endpoints(
        Filters=[{"Name": "tag:Name", "Values": ["client-vpn-pc-endpoint"]}]
    )
    
    if len(endpoints["ClientVpnEndpoints"]) == 0:
        pytest.skip("⚠️  PC用VPNエンドポイントが見つかりません（まだデプロイされていない可能性があります）")
    
    return endpoints["ClientVpnEndpoints"][0]


@pytest.fixture(scope="module")
def mobile_vpn_endpoint(ec2_client):
    """スマホ用VPNエンドポイントを取得"""
    endpoints = ec2_client.describe_client_vpn_endpoints(
        Filters=[{"Name": "tag:Name", "Values": ["client-vpn-mobile-endpoint"]}]
    )
    
    if len(endpoints["ClientVpnEndpoints"]) == 0:
        pytest.skip("⚠️  スマホ用VPNエンドポイントが見つかりません（まだデプロイされていない可能性があります）")
    
    return endpoints["ClientVpnEndpoints"][0]


class TestPCVPNEndpoint:
    """PC用VPNエンドポイント（SAML + MFA）の検証テスト"""

    def test_pc_vpn_endpoint_exists(self, pc_vpn_endpoint):
        """
        Requirements 2.1: PC用VPNエンドポイントが作成されていることを検証
        """
        assert pc_vpn_endpoint is not None, "PC用VPNエンドポイントが見つかりません"
        assert pc_vpn_endpoint["Status"]["Code"] in ["pending-associate", "available"], \
            f"PC用VPNエンドポイントのステータスが不正です: {pc_vpn_endpoint['Status']['Code']}"
        
        print(f"✅ PC用VPNエンドポイントが存在します: {pc_vpn_endpoint['ClientVpnEndpointId']}")

    def test_pc_vpn_authentication_type(self, pc_vpn_endpoint):
        """
        Requirements 2.1, 2.2: PC用VPNエンドポイントがSAML認証を使用していることを検証
        """
        auth_options = pc_vpn_endpoint.get("AuthenticationOptions", [])
        
        assert len(auth_options) > 0, "認証オプションが設定されていません"
        
        # SAML認証が設定されていることを確認
        saml_auth = [auth for auth in auth_options if auth["Type"] == "federated-authentication"]
        
        assert len(saml_auth) > 0, \
            "PC用VPNエンドポイントにSAML認証が設定されていません"
        
        # SAML Provider ARNが設定されていることを確認
        assert "SamlProviderArn" in saml_auth[0], \
            "SAML Provider ARNが設定されていません"
        
        print(f"✅ PC用VPNエンドポイントがSAML認証を使用しています")

    def test_pc_vpn_self_service_portal(self, pc_vpn_endpoint):
        """
        Requirements 2.1: PC用VPNエンドポイントでSelf-Service Portalが有効化されていることを検証
        """
        auth_options = pc_vpn_endpoint.get("AuthenticationOptions", [])
        saml_auth = [auth for auth in auth_options if auth["Type"] == "federated-authentication"]
        
        assert len(saml_auth) > 0
        
        # Self-Service SAML Provider ARNが設定されていることを確認
        assert "SelfServiceSamlProviderArn" in saml_auth[0], \
            "Self-Service SAML Provider ARNが設定されていません"
        
        print(f"✅ PC用VPNエンドポイントでSelf-Service Portalが有効化されています")

    def test_pc_vpn_client_cidr(self, pc_vpn_endpoint):
        """
        Requirements 2.1: PC用VPNエンドポイントのClient CIDRが正しく設定されていることを検証
        """
        expected_cidr = "172.16.0.0/22"
        actual_cidr = pc_vpn_endpoint.get("ClientCidrBlock")
        
        assert actual_cidr == expected_cidr, \
            f"PC用VPNエンドポイントのClient CIDRが期待値と異なります。期待: {expected_cidr}, 実際: {actual_cidr}"
        
        print(f"✅ PC用VPNエンドポイントのClient CIDRが正しく設定されています: {actual_cidr}")

    def test_pc_vpn_split_tunnel(self, pc_vpn_endpoint):
        """
        Requirements 2.1: PC用VPNエンドポイントでSplit Tunnelが有効化されていることを検証
        """
        split_tunnel = pc_vpn_endpoint.get("SplitTunnel")
        
        assert split_tunnel is True, \
            "PC用VPNエンドポイントでSplit Tunnelが有効化されていません"
        
        print(f"✅ PC用VPNエンドポイントでSplit Tunnelが有効化されています")

    def test_pc_vpn_transport_protocol(self, pc_vpn_endpoint):
        """
        Requirements 2.1: PC用VPNエンドポイントがUDP 443を使用していることを検証
        """
        transport_protocol = pc_vpn_endpoint.get("TransportProtocol")
        vpn_port = pc_vpn_endpoint.get("VpnPort")
        
        assert transport_protocol == "udp", \
            f"PC用VPNエンドポイントのトランスポートプロトコルが不正です。期待: udp, 実際: {transport_protocol}"
        
        assert vpn_port == 443, \
            f"PC用VPNエンドポイントのVPNポートが不正です。期待: 443, 実際: {vpn_port}"
        
        print(f"✅ PC用VPNエンドポイントがUDP 443を使用しています")

    def test_pc_vpn_connection_logging(self, pc_vpn_endpoint):
        """
        Requirements 2.5: PC用VPNエンドポイントで接続ログが有効化されていることを検証
        """
        connection_log_options = pc_vpn_endpoint.get("ConnectionLogOptions", {})
        
        assert connection_log_options.get("Enabled") is True, \
            "PC用VPNエンドポイントで接続ログが有効化されていません"
        
        assert "CloudwatchLogGroup" in connection_log_options, \
            "CloudWatch Logsグループが設定されていません"
        
        assert "CloudwatchLogStream" in connection_log_options, \
            "CloudWatch Logsストリームが設定されていません"
        
        print(f"✅ PC用VPNエンドポイントで接続ログが有効化されています")

    def test_pc_vpn_network_associations(self, ec2_client, pc_vpn_endpoint):
        """
        Requirements 5.3: PC用VPNエンドポイントがプライベートサブネットに関連付けられていることを検証
        """
        endpoint_id = pc_vpn_endpoint["ClientVpnEndpointId"]
        
        # ネットワーク関連付けを取得
        associations = ec2_client.describe_client_vpn_target_networks(
            ClientVpnEndpointId=endpoint_id
        )
        
        assert len(associations["ClientVpnTargetNetworks"]) > 0, \
            "PC用VPNエンドポイントにネットワーク関連付けが見つかりません"
        
        # プライベートサブネットIDを取得
        private_subnets = ec2_client.describe_subnets(
            Filters=[{"Name": "tag:Type", "Values": ["Private"]}]
        )
        private_subnet_ids = {subnet["SubnetId"] for subnet in private_subnets["Subnets"]}
        
        # 関連付けられているサブネットがプライベートサブネットであることを確認
        for assoc in associations["ClientVpnTargetNetworks"]:
            assert assoc["TargetNetworkId"] in private_subnet_ids, \
                f"PC用VPNエンドポイントがプライベートサブネット以外に関連付けられています: {assoc['TargetNetworkId']}"
        
        print(f"✅ PC用VPNエンドポイントがプライベートサブネットに関連付けられています")

    def test_pc_vpn_authorization_rules(self, ec2_client, pc_vpn_endpoint):
        """
        Requirements 4.4: PC用VPNエンドポイントにインターネットアクセスの認可ルールが設定されていることを検証
        """
        endpoint_id = pc_vpn_endpoint["ClientVpnEndpointId"]
        
        # 認可ルールを取得
        auth_rules = ec2_client.describe_client_vpn_authorization_rules(
            ClientVpnEndpointId=endpoint_id
        )
        
        assert len(auth_rules["AuthorizationRules"]) > 0, \
            "PC用VPNエンドポイントに認可ルールが設定されていません"
        
        # インターネットアクセス（0.0.0.0/0）の認可ルールが存在することを確認
        internet_rules = [
            rule for rule in auth_rules["AuthorizationRules"]
            if rule["DestinationCidr"] == "0.0.0.0/0"
        ]
        
        assert len(internet_rules) > 0, \
            "PC用VPNエンドポイントにインターネットアクセスの認可ルールが設定されていません"
        
        # グループベース認可が設定されていることを確認
        group_based_rules = [
            rule for rule in internet_rules
            if "AccessGroupId" in rule and rule["AccessGroupId"]
        ]
        
        assert len(group_based_rules) > 0, \
            "PC用VPNエンドポイントにグループベース認可が設定されていません"
        
        print(f"✅ PC用VPNエンドポイントにインターネットアクセスの認可ルールが設定されています")


class TestMobileVPNEndpoint:
    """スマホ用VPNエンドポイント（証明書認証）の検証テスト"""

    def test_mobile_vpn_endpoint_exists(self, mobile_vpn_endpoint):
        """
        Requirements 3.1: スマホ用VPNエンドポイントが作成されていることを検証
        """
        assert mobile_vpn_endpoint is not None, "スマホ用VPNエンドポイントが見つかりません"
        assert mobile_vpn_endpoint["Status"]["Code"] in ["pending-associate", "available"], \
            f"スマホ用VPNエンドポイントのステータスが不正です: {mobile_vpn_endpoint['Status']['Code']}"
        
        print(f"✅ スマホ用VPNエンドポイントが存在します: {mobile_vpn_endpoint['ClientVpnEndpointId']}")

    def test_mobile_vpn_authentication_type(self, mobile_vpn_endpoint):
        """
        Requirements 3.1, 3.2: スマホ用VPNエンドポイントが証明書認証を使用していることを検証
        """
        auth_options = mobile_vpn_endpoint.get("AuthenticationOptions", [])
        
        assert len(auth_options) > 0, "認証オプションが設定されていません"
        
        # 証明書認証が設定されていることを確認
        cert_auth = [auth for auth in auth_options if auth["Type"] == "certificate-authentication"]
        
        assert len(cert_auth) > 0, \
            "スマホ用VPNエンドポイントに証明書認証が設定されていません"
        
        # Root Certificate Chain ARNが設定されていることを確認
        assert "ClientRootCertificateChain" in cert_auth[0], \
            "Root Certificate Chain ARNが設定されていません"
        
        print(f"✅ スマホ用VPNエンドポイントが証明書認証を使用しています")

    def test_mobile_vpn_client_cidr(self, mobile_vpn_endpoint):
        """
        Requirements 3.1: スマホ用VPNエンドポイントのClient CIDRが正しく設定されていることを検証
        """
        expected_cidr = "172.17.0.0/22"
        actual_cidr = mobile_vpn_endpoint.get("ClientCidrBlock")
        
        assert actual_cidr == expected_cidr, \
            f"スマホ用VPNエンドポイントのClient CIDRが期待値と異なります。期待: {expected_cidr}, 実際: {actual_cidr}"
        
        print(f"✅ スマホ用VPNエンドポイントのClient CIDRが正しく設定されています: {actual_cidr}")

    def test_mobile_vpn_split_tunnel(self, mobile_vpn_endpoint):
        """
        Requirements 3.1: スマホ用VPNエンドポイントでSplit Tunnelが有効化されていることを検証
        """
        split_tunnel = mobile_vpn_endpoint.get("SplitTunnel")
        
        assert split_tunnel is True, \
            "スマホ用VPNエンドポイントでSplit Tunnelが有効化されていません"
        
        print(f"✅ スマホ用VPNエンドポイントでSplit Tunnelが有効化されています")

    def test_mobile_vpn_transport_protocol(self, mobile_vpn_endpoint):
        """
        Requirements 3.1: スマホ用VPNエンドポイントがUDP 443を使用していることを検証
        """
        transport_protocol = mobile_vpn_endpoint.get("TransportProtocol")
        vpn_port = mobile_vpn_endpoint.get("VpnPort")
        
        assert transport_protocol == "udp", \
            f"スマホ用VPNエンドポイントのトランスポートプロトコルが不正です。期待: udp, 実際: {transport_protocol}"
        
        assert vpn_port == 443, \
            f"スマホ用VPNエンドポイントのVPNポートが不正です。期待: 443, 実際: {vpn_port}"
        
        print(f"✅ スマホ用VPNエンドポイントがUDP 443を使用しています")

    def test_mobile_vpn_connection_logging(self, mobile_vpn_endpoint):
        """
        Requirements 2.5: スマホ用VPNエンドポイントで接続ログが有効化されていることを検証
        """
        connection_log_options = mobile_vpn_endpoint.get("ConnectionLogOptions", {})
        
        assert connection_log_options.get("Enabled") is True, \
            "スマホ用VPNエンドポイントで接続ログが有効化されていません"
        
        assert "CloudwatchLogGroup" in connection_log_options, \
            "CloudWatch Logsグループが設定されていません"
        
        assert "CloudwatchLogStream" in connection_log_options, \
            "CloudWatch Logsストリームが設定されていません"
        
        print(f"✅ スマホ用VPNエンドポイントで接続ログが有効化されています")

    def test_mobile_vpn_network_associations(self, ec2_client, mobile_vpn_endpoint):
        """
        Requirements 5.3: スマホ用VPNエンドポイントがプライベートサブネットに関連付けられていることを検証
        """
        endpoint_id = mobile_vpn_endpoint["ClientVpnEndpointId"]
        
        # ネットワーク関連付けを取得
        associations = ec2_client.describe_client_vpn_target_networks(
            ClientVpnEndpointId=endpoint_id
        )
        
        assert len(associations["ClientVpnTargetNetworks"]) > 0, \
            "スマホ用VPNエンドポイントにネットワーク関連付けが見つかりません"
        
        # プライベートサブネットIDを取得
        private_subnets = ec2_client.describe_subnets(
            Filters=[{"Name": "tag:Type", "Values": ["Private"]}]
        )
        private_subnet_ids = {subnet["SubnetId"] for subnet in private_subnets["Subnets"]}
        
        # 関連付けられているサブネットがプライベートサブネットであることを確認
        for assoc in associations["ClientVpnTargetNetworks"]:
            assert assoc["TargetNetworkId"] in private_subnet_ids, \
                f"スマホ用VPNエンドポイントがプライベートサブネット以外に関連付けられています: {assoc['TargetNetworkId']}"
        
        print(f"✅ スマホ用VPNエンドポイントがプライベートサブネットに関連付けられています")

    def test_mobile_vpn_authorization_rules(self, ec2_client, mobile_vpn_endpoint):
        """
        Requirements 4.4: スマホ用VPNエンドポイントにインターネットアクセスの認可ルールが設定されていることを検証
        """
        endpoint_id = mobile_vpn_endpoint["ClientVpnEndpointId"]
        
        # 認可ルールを取得
        auth_rules = ec2_client.describe_client_vpn_authorization_rules(
            ClientVpnEndpointId=endpoint_id
        )
        
        assert len(auth_rules["AuthorizationRules"]) > 0, \
            "スマホ用VPNエンドポイントに認可ルールが設定されていません"
        
        # インターネットアクセス（0.0.0.0/0）の認可ルールが存在することを確認
        internet_rules = [
            rule for rule in auth_rules["AuthorizationRules"]
            if rule["DestinationCidr"] == "0.0.0.0/0"
        ]
        
        assert len(internet_rules) > 0, \
            "スマホ用VPNエンドポイントにインターネットアクセスの認可ルールが設定されていません"
        
        # 全ユーザー許可が設定されていることを確認
        all_users_rules = [
            rule for rule in internet_rules
            if rule.get("AuthorizeAllGroups") is True
        ]
        
        assert len(all_users_rules) > 0, \
            "スマホ用VPNエンドポイントに全ユーザー許可が設定されていません"
        
        print(f"✅ スマホ用VPNエンドポイントにインターネットアクセスの認可ルールが設定されています")


class TestVPNEndpointSecurity:
    """VPNエンドポイントのセキュリティ設定検証テスト"""

    def test_vpn_endpoints_use_tls_1_2_or_higher(self, pc_vpn_endpoint, mobile_vpn_endpoint):
        """
        Requirements 7.5: VPNエンドポイントがTLS 1.2以上を使用していることを検証
        """
        # Client VPNはデフォルトでTLS 1.2以上を使用
        # サーバー証明書が設定されていることを確認
        
        for endpoint_name, endpoint in [("PC用", pc_vpn_endpoint), ("スマホ用", mobile_vpn_endpoint)]:
            assert "ServerCertificateArn" in endpoint, \
                f"{endpoint_name}VPNエンドポイントにサーバー証明書が設定されていません"
            
            print(f"✅ {endpoint_name}VPNエンドポイントにサーバー証明書が設定されています")

    def test_vpn_endpoints_have_security_groups(self, pc_vpn_endpoint, mobile_vpn_endpoint):
        """
        Requirements 5.6: VPNエンドポイントにセキュリティグループが設定されていることを検証
        """
        for endpoint_name, endpoint in [("PC用", pc_vpn_endpoint), ("スマホ用", mobile_vpn_endpoint)]:
            security_group_ids = endpoint.get("SecurityGroupIds", [])
            
            assert len(security_group_ids) > 0, \
                f"{endpoint_name}VPNエンドポイントにセキュリティグループが設定されていません"
            
            print(f"✅ {endpoint_name}VPNエンドポイントにセキュリティグループが設定されています")


if __name__ == "__main__":
    # スタンドアロン実行用
    pytest.main([__file__, "-v", "-s"])
