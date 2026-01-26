# CloudTrail Configuration for AWS Client VPN Infrastructure
# Requirements: 7.5 - CloudTrailでAPI呼び出しを記録する

# S3バケット（CloudTrailログ用）
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "client-vpn-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "client-vpn-cloudtrail-logs"
    Purpose     = "CloudTrail Logs Storage"
    Environment = "production"
  }
}

# S3バケットバージョニング
resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3バケット暗号化（サーバーサイド暗号化 - AES256）
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3バケットパブリックアクセスブロック
resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3バケットポリシー（CloudTrailアクセス許可）
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.cloudtrail]
}

# CloudTrail
resource "aws_cloudtrail" "main" {
  name                          = "client-vpn-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
    # Client VPN API呼び出しは管理イベントとして自動的に記録されます
  }

  tags = {
    Name        = "client-vpn-cloudtrail"
    Purpose     = "API Call Auditing"
    Environment = "production"
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# 現在のAWSアカウントIDを取得
data "aws_caller_identity" "current" {}
