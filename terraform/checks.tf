# ============================================================================
# Continuous Validation (Terraform 1.5+ check blocks)
# ============================================================================
# SAST: デプロイ後の継続的なセキュリティ検証
# ============================================================================

# S3バケットのパブリックアクセスが確実にブロックされていることを検証
check "cloudtrail_bucket_not_public" {
  data "aws_s3_bucket" "cloudtrail_check" {
    bucket = aws_s3_bucket.cloudtrail.id
  }

  assert {
    condition     = data.aws_s3_bucket.cloudtrail_check.bucket == aws_s3_bucket.cloudtrail.id
    error_message = "CloudTrail S3 bucket configuration mismatch detected."
  }
}

# CloudTrailのログファイル検証が有効であることを確認
check "cloudtrail_log_validation" {
  assert {
    condition     = aws_cloudtrail.main.enable_log_file_validation == true
    error_message = "CloudTrail log file validation must be enabled."
  }
}

# CloudTrailがマルチリージョンであることを確認
check "cloudtrail_multi_region" {
  assert {
    condition     = aws_cloudtrail.main.is_multi_region_trail == true
    error_message = "CloudTrail must be configured as multi-region trail."
  }
}

# VPN接続ログが有効であることを確認
check "vpn_pc_logging_enabled" {
  assert {
    condition     = aws_ec2_client_vpn_endpoint.pc.connection_log_options[0].enabled == true
    error_message = "PC VPN connection logging must be enabled."
  }
}

check "vpn_mobile_logging_enabled" {
  assert {
    condition     = aws_ec2_client_vpn_endpoint.mobile.connection_log_options[0].enabled == true
    error_message = "Mobile VPN connection logging must be enabled."
  }
}
