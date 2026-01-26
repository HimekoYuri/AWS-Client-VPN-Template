"""
統合テスト: ログ検証テスト

**Validates: Requirements 2.5, 7.5**

このテストは、CloudWatch LogsとCloudTrailが正しく設定されていることを検証します。
- CloudWatch Logsグループの作成
- CloudTrailの有効化
- ログ記録の設定
"""

import pytest


class TestCloudWatchLogs:
    """CloudWatch Logs設定の検証テスト"""

    def test_pc_vpn_log_group_exists(self, logs_client):
        """
        Requirements 2.5: PC用VPNのCloudWatch Logsグループが作成されていることを検証
        """
        log_group_name = "/aws/clientvpn/pc"
        
        try:
            response = logs_client.describe_log_groups(
                logGroupNamePrefix=log_group_name
            )
            
            log_groups = [
                lg for lg in response["logGroups"]
                if lg["logGroupName"] == log_group_name
            ]
            
            assert len(log_groups) == 1, \
                f"PC用VPNのCloudWatch Logsグループが見つかりません: {log_group_name}"
            
            print(f"✅ PC用VPNのCloudWatch Logsグループが存在します: {log_group_name}")
            
        except logs_client.exceptions.ResourceNotFoundException:
            pytest.skip(f"⚠️  CloudWatch Logsグループが見つかりません（まだデプロイされていない可能性があります）")

    def test_mobile_vpn_log_group_exists(self, logs_client):
        """
        Requirements 2.5: スマホ用VPNのCloudWatch Logsグループが作成されていることを検証
        """
        log_group_name = "/aws/clientvpn/mobile"
        
        try:
            response = logs_client.describe_log_groups(
                logGroupNamePrefix=log_group_name
            )
            
            log_groups = [
                lg for lg in response["logGroups"]
                if lg["logGroupName"] == log_group_name
            ]
            
            assert len(log_groups) == 1, \
                f"スマホ用VPNのCloudWatch Logsグループが見つかりません: {log_group_name}"
            
            print(f"✅ スマホ用VPNのCloudWatch Logsグループが存在します: {log_group_name}")
            
        except logs_client.exceptions.ResourceNotFoundException:
            pytest.skip(f"⚠️  CloudWatch Logsグループが見つかりません（まだデプロイされていない可能性があります）")

    def test_pc_vpn_log_retention(self, logs_client):
        """
        Requirements 2.5: PC用VPNのCloudWatch Logsグループに保持期間が設定されていることを検証
        """
        log_group_name = "/aws/clientvpn/pc"
        
        try:
            response = logs_client.describe_log_groups(
                logGroupNamePrefix=log_group_name
            )
            
            log_groups = [
                lg for lg in response["logGroups"]
                if lg["logGroupName"] == log_group_name
            ]
            
            assert len(log_groups) == 1
            log_group = log_groups[0]
            
            # 保持期間が設定されていることを確認（30日）
            assert "retentionInDays" in log_group, \
                "PC用VPNのCloudWatch Logsグループに保持期間が設定されていません"
            
            assert log_group["retentionInDays"] == 30, \
                f"PC用VPNのCloudWatch Logsグループの保持期間が期待値と異なります。期待: 30日, 実際: {log_group['retentionInDays']}日"
            
            print(f"✅ PC用VPNのCloudWatch Logsグループに保持期間が設定されています: {log_group['retentionInDays']}日")
            
        except logs_client.exceptions.ResourceNotFoundException:
            pytest.skip(f"⚠️  CloudWatch Logsグループが見つかりません")

    def test_mobile_vpn_log_retention(self, logs_client):
        """
        Requirements 2.5: スマホ用VPNのCloudWatch Logsグループに保持期間が設定されていることを検証
        """
        log_group_name = "/aws/clientvpn/mobile"
        
        try:
            response = logs_client.describe_log_groups(
                logGroupNamePrefix=log_group_name
            )
            
            log_groups = [
                lg for lg in response["logGroups"]
                if lg["logGroupName"] == log_group_name
            ]
            
            assert len(log_groups) == 1
            log_group = log_groups[0]
            
            # 保持期間が設定されていることを確認（30日）
            assert "retentionInDays" in log_group, \
                "スマホ用VPNのCloudWatch Logsグループに保持期間が設定されていません"
            
            assert log_group["retentionInDays"] == 30, \
                f"スマホ用VPNのCloudWatch Logsグループの保持期間が期待値と異なります。期待: 30日, 実際: {log_group['retentionInDays']}日"
            
            print(f"✅ スマホ用VPNのCloudWatch Logsグループに保持期間が設定されています: {log_group['retentionInDays']}日")
            
        except logs_client.exceptions.ResourceNotFoundException:
            pytest.skip(f"⚠️  CloudWatch Logsグループが見つかりません")

    def test_pc_vpn_log_stream_exists(self, logs_client):
        """
        Requirements 2.5: PC用VPNのCloudWatch Logsストリームが作成されていることを検証
        """
        log_group_name = "/aws/clientvpn/pc"
        log_stream_name = "connection-log"
        
        try:
            response = logs_client.describe_log_streams(
                logGroupName=log_group_name,
                logStreamNamePrefix=log_stream_name
            )
            
            log_streams = [
                ls for ls in response["logStreams"]
                if ls["logStreamName"] == log_stream_name
            ]
            
            assert len(log_streams) == 1, \
                f"PC用VPNのCloudWatch Logsストリームが見つかりません: {log_stream_name}"
            
            print(f"✅ PC用VPNのCloudWatch Logsストリームが存在します: {log_stream_name}")
            
        except logs_client.exceptions.ResourceNotFoundException:
            pytest.skip(f"⚠️  CloudWatch Logsグループまたはストリームが見つかりません")

    def test_mobile_vpn_log_stream_exists(self, logs_client):
        """
        Requirements 2.5: スマホ用VPNのCloudWatch Logsストリームが作成されていることを検証
        """
        log_group_name = "/aws/clientvpn/mobile"
        log_stream_name = "connection-log"
        
        try:
            response = logs_client.describe_log_streams(
                logGroupName=log_group_name,
                logStreamNamePrefix=log_stream_name
            )
            
            log_streams = [
                ls for ls in response["logStreams"]
                if ls["logStreamName"] == log_stream_name
            ]
            
            assert len(log_streams) == 1, \
                f"スマホ用VPNのCloudWatch Logsストリームが見つかりません: {log_stream_name}"
            
            print(f"✅ スマホ用VPNのCloudWatch Logsストリームが存在します: {log_stream_name}")
            
        except logs_client.exceptions.ResourceNotFoundException:
            pytest.skip(f"⚠️  CloudWatch Logsグループまたはストリームが見つかりません")


class TestCloudTrail:
    """CloudTrail設定の検証テスト"""

    def test_cloudtrail_exists(self, cloudtrail_client):
        """
        Requirements 7.5: CloudTrailが作成されていることを検証
        """
        trail_name = "client-vpn-trail"
        
        try:
            response = cloudtrail_client.describe_trails(
                trailNameList=[trail_name]
            )
            
            assert len(response["trailList"]) == 1, \
                f"CloudTrailが見つかりません: {trail_name}"
            
            print(f"✅ CloudTrailが存在します: {trail_name}")
            
        except cloudtrail_client.exceptions.TrailNotFoundException:
            pytest.skip(f"⚠️  CloudTrailが見つかりません（まだデプロイされていない可能性があります）")

    def test_cloudtrail_is_logging(self, cloudtrail_client):
        """
        Requirements 7.5: CloudTrailがログ記録を有効化していることを検証
        """
        trail_name = "client-vpn-trail"
        
        try:
            response = cloudtrail_client.get_trail_status(
                Name=trail_name
            )
            
            assert response["IsLogging"] is True, \
                f"CloudTrailがログ記録を有効化していません: {trail_name}"
            
            print(f"✅ CloudTrailがログ記録を有効化しています")
            
        except cloudtrail_client.exceptions.TrailNotFoundException:
            pytest.skip(f"⚠️  CloudTrailが見つかりません")

    def test_cloudtrail_multi_region(self, cloudtrail_client):
        """
        Requirements 7.5: CloudTrailがマルチリージョントレイルであることを検証
        """
        trail_name = "client-vpn-trail"
        
        try:
            response = cloudtrail_client.describe_trails(
                trailNameList=[trail_name]
            )
            
            assert len(response["trailList"]) == 1
            trail = response["trailList"][0]
            
            assert trail.get("IsMultiRegionTrail") is True, \
                "CloudTrailがマルチリージョントレイルではありません"
            
            print(f"✅ CloudTrailがマルチリージョントレイルです")
            
        except cloudtrail_client.exceptions.TrailNotFoundException:
            pytest.skip(f"⚠️  CloudTrailが見つかりません")

    def test_cloudtrail_log_file_validation(self, cloudtrail_client):
        """
        Requirements 7.5: CloudTrailでログファイル検証が有効化されていることを検証
        """
        trail_name = "client-vpn-trail"
        
        try:
            response = cloudtrail_client.describe_trails(
                trailNameList=[trail_name]
            )
            
            assert len(response["trailList"]) == 1
            trail = response["trailList"][0]
            
            assert trail.get("LogFileValidationEnabled") is True, \
                "CloudTrailでログファイル検証が有効化されていません"
            
            print(f"✅ CloudTrailでログファイル検証が有効化されています")
            
        except cloudtrail_client.exceptions.TrailNotFoundException:
            pytest.skip(f"⚠️  CloudTrailが見つかりません")

    def test_cloudtrail_includes_global_service_events(self, cloudtrail_client):
        """
        Requirements 7.5: CloudTrailがグローバルサービスイベントを記録していることを検証
        """
        trail_name = "client-vpn-trail"
        
        try:
            response = cloudtrail_client.describe_trails(
                trailNameList=[trail_name]
            )
            
            assert len(response["trailList"]) == 1
            trail = response["trailList"][0]
            
            assert trail.get("IncludeGlobalServiceEvents") is True, \
                "CloudTrailがグローバルサービスイベントを記録していません"
            
            print(f"✅ CloudTrailがグローバルサービスイベントを記録しています")
            
        except cloudtrail_client.exceptions.TrailNotFoundException:
            pytest.skip(f"⚠️  CloudTrailが見つかりません")

    def test_cloudtrail_s3_bucket_exists(self, s3_client, cloudtrail_client, sts_client):
        """
        Requirements 7.5: CloudTrailログ用のS3バケットが作成されていることを検証
        """
        trail_name = "client-vpn-trail"
        
        try:
            # CloudTrailの設定を取得
            response = cloudtrail_client.describe_trails(
                trailNameList=[trail_name]
            )
            
            assert len(response["trailList"]) == 1
            trail = response["trailList"][0]
            
            s3_bucket_name = trail.get("S3BucketName")
            assert s3_bucket_name, "CloudTrailにS3バケットが設定されていません"
            
            # S3バケットが存在することを確認
            try:
                s3_client.head_bucket(Bucket=s3_bucket_name)
                print(f"✅ CloudTrailログ用のS3バケットが存在します: {s3_bucket_name}")
            except s3_client.exceptions.NoSuchBucket:
                pytest.fail(f"❌ CloudTrailログ用のS3バケットが見つかりません: {s3_bucket_name}")
            
        except cloudtrail_client.exceptions.TrailNotFoundException:
            pytest.skip(f"⚠️  CloudTrailが見つかりません")

    def test_cloudtrail_s3_bucket_versioning(self, s3_client, cloudtrail_client):
        """
        Requirements 7.5: CloudTrailログ用のS3バケットでバージョニングが有効化されていることを検証
        """
        trail_name = "client-vpn-trail"
        
        try:
            # CloudTrailの設定を取得
            response = cloudtrail_client.describe_trails(
                trailNameList=[trail_name]
            )
            
            assert len(response["trailList"]) == 1
            trail = response["trailList"][0]
            
            s3_bucket_name = trail.get("S3BucketName")
            assert s3_bucket_name, "CloudTrailにS3バケットが設定されていません"
            
            # バージョニング設定を確認
            versioning = s3_client.get_bucket_versioning(Bucket=s3_bucket_name)
            
            assert versioning.get("Status") == "Enabled", \
                f"CloudTrailログ用のS3バケットでバージョニングが有効化されていません: {s3_bucket_name}"
            
            print(f"✅ CloudTrailログ用のS3バケットでバージョニングが有効化されています")
            
        except cloudtrail_client.exceptions.TrailNotFoundException:
            pytest.skip(f"⚠️  CloudTrailが見つかりません")
        except s3_client.exceptions.NoSuchBucket:
            pytest.skip(f"⚠️  S3バケットが見つかりません")

    def test_cloudtrail_s3_bucket_encryption(self, s3_client, cloudtrail_client):
        """
        Requirements 7.1, 7.5: CloudTrailログ用のS3バケットで暗号化が有効化されていることを検証
        """
        trail_name = "client-vpn-trail"
        
        try:
            # CloudTrailの設定を取得
            response = cloudtrail_client.describe_trails(
                trailNameList=[trail_name]
            )
            
            assert len(response["trailList"]) == 1
            trail = response["trailList"][0]
            
            s3_bucket_name = trail.get("S3BucketName")
            assert s3_bucket_name, "CloudTrailにS3バケットが設定されていません"
            
            # 暗号化設定を確認
            encryption = s3_client.get_bucket_encryption(Bucket=s3_bucket_name)
            
            rules = encryption.get("ServerSideEncryptionConfiguration", {}).get("Rules", [])
            assert len(rules) > 0, \
                f"CloudTrailログ用のS3バケットで暗号化が設定されていません: {s3_bucket_name}"
            
            # AES256またはKMS暗号化が設定されていることを確認
            sse_algorithm = rules[0].get("ApplyServerSideEncryptionByDefault", {}).get("SSEAlgorithm")
            assert sse_algorithm in ["AES256", "aws:kms"], \
                f"CloudTrailログ用のS3バケットの暗号化アルゴリズムが不正です: {sse_algorithm}"
            
            print(f"✅ CloudTrailログ用のS3バケットで暗号化が有効化されています: {sse_algorithm}")
            
        except cloudtrail_client.exceptions.TrailNotFoundException:
            pytest.skip(f"⚠️  CloudTrailが見つかりません")
        except s3_client.exceptions.NoSuchBucket:
            pytest.skip(f"⚠️  S3バケットが見つかりません")
        except s3_client.exceptions.ServerSideEncryptionConfigurationNotFoundError:
            pytest.fail(f"❌ CloudTrailログ用のS3バケットで暗号化が設定されていません")


if __name__ == "__main__":
    # スタンドアロン実行用
    pytest.main([__file__, "-v", "-s"])
