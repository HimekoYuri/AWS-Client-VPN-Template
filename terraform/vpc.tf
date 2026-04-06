# ============================================================================
# VPC Configuration
# ============================================================================
# Requirements: 5.1 - VPCを作成し、適切なCIDRブロックを割り当てる
# ============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "client-vpn-vpc"
  }
}

# ============================================================================
# VPC Flow Logs - ネットワークトラフィック監視
# ============================================================================
# SAST: VPC Flow Logsを有効化し、不審なトラフィックを検知可能にする

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name              = "/aws/vpc/flow-logs/${aws_vpc.main.id}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logs.arn

  tags = {
    Name    = "vpc-flow-logs"
    Purpose = "VPC Network Traffic Monitoring"
  }
}

resource "aws_flow_log" "main" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.main.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  iam_role_arn             = aws_iam_role.vpc_flow_logs[0].arn
  max_aggregation_interval = 60

  tags = {
    Name    = "client-vpn-vpc-flow-log"
    Purpose = "Network Traffic Audit"
  }
}

# VPC Flow Logs用IAMロール
resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name = "client-vpn-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = {
    Name    = "vpc-flow-logs-role"
    Purpose = "VPC Flow Logs Delivery"
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name = "vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}
