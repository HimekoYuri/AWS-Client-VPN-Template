# ============================================================================
# CloudWatch Logs - VPN接続ログ
# ============================================================================
# Requirements: 2.5 - VPN接続ログをCloudWatch Logsに記録する
# SAST: KMS暗号化を有効化、保持期間を変数化
# ============================================================================

# ----------------------------------------------------------------------------
# PC用VPN接続ログ
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "vpn_pc" {
  name              = "/aws/clientvpn/pc"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logs.arn

  tags = {
    Name    = "client-vpn-pc-logs"
    Purpose = "PC VPN Connection Logs"
  }
}

resource "aws_cloudwatch_log_stream" "vpn_pc" {
  name           = "connection-log"
  log_group_name = aws_cloudwatch_log_group.vpn_pc.name
}

# ----------------------------------------------------------------------------
# スマホ用VPN接続ログ
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "vpn_mobile" {
  name              = "/aws/clientvpn/mobile"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logs.arn

  tags = {
    Name    = "client-vpn-mobile-logs"
    Purpose = "Mobile VPN Connection Logs"
  }
}

resource "aws_cloudwatch_log_stream" "vpn_mobile" {
  name           = "connection-log"
  log_group_name = aws_cloudwatch_log_group.vpn_mobile.name
}
