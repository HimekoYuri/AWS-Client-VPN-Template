# ============================================================================
# KMS Keys - 暗号化キー管理
# ============================================================================
# var.enable_kms_encryption = true の場合のみKMSキーを作成
# false の場合はAES256 / デフォルト暗号化にフォールバック
# ============================================================================

locals {
  # KMS ARN (無効時はnull)
  logs_kms_key_arn       = var.enable_kms_encryption ? aws_kms_key.logs[0].arn : null
  cloudtrail_kms_key_arn = var.enable_kms_encryption ? aws_kms_key.cloudtrail[0].arn : null
}

# ----------------------------------------------------------------------------
# CloudWatch Logs暗号化用KMSキー
# ----------------------------------------------------------------------------
resource "aws_kms_key" "logs" {
  count = var.enable_kms_encryption ? 1 : 0

  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "client-vpn-logs-kms"
    Purpose = "CloudWatch Logs Encryption"
  }
}

resource "aws_kms_alias" "logs" {
  count = var.enable_kms_encryption ? 1 : 0

  name          = "alias/client-vpn-logs"
  target_key_id = aws_kms_key.logs[0].key_id
}

# ----------------------------------------------------------------------------
# S3/CloudTrail暗号化用KMSキー
# ----------------------------------------------------------------------------
resource "aws_kms_key" "cloudtrail" {
  count = var.enable_kms_encryption ? 1 : 0

  description             = "KMS key for CloudTrail and S3 encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudTrail"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "client-vpn-cloudtrail-kms"
    Purpose = "CloudTrail and S3 Encryption"
  }
}

resource "aws_kms_alias" "cloudtrail" {
  count = var.enable_kms_encryption ? 1 : 0

  name          = "alias/client-vpn-cloudtrail"
  target_key_id = aws_kms_key.cloudtrail[0].key_id
}
