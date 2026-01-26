# ============================================================================
# CloudWatch Logs - VPN接続ログ
# ============================================================================
# 
# このファイルは、Client VPNエンドポイントの接続ログを記録するための
# CloudWatch Logsグループとストリームを定義します。
#
# 要件:
# - Requirements 2.5: VPN接続ログをCloudWatch Logsに記録する
# - 保持期間: 30日
# - PC用とスマホ用で別々のロググループを使用
# ============================================================================

# ----------------------------------------------------------------------------
# PC用VPN接続ログ
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "vpn_pc" {
  name              = "/aws/clientvpn/pc"
  retention_in_days = 30

  tags = {
    Name        = "client-vpn-pc-logs"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "PC VPN Connection Logs"
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
  retention_in_days = 30

  tags = {
    Name        = "client-vpn-mobile-logs"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Mobile VPN Connection Logs"
  }
}

resource "aws_cloudwatch_log_stream" "vpn_mobile" {
  name           = "connection-log"
  log_group_name = aws_cloudwatch_log_group.vpn_mobile.name
}
