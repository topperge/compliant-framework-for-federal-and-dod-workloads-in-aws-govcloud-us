#
# Consolidated logging support (for same account copy)
#
resource "aws_iam_role" "consolidated_logs_replication" {
  name = "ConsolidatedLogsReplicationRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = ["sts:AssumeRole"]
    }]
  })
  tags = var.tags
}

data "aws_iam_policy_document" "consolidated_logs_replication" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
    ]
    resources = flatten([
      for b in values(local.source_buckets) : [b.arn, "${b.arn}/*"]
    ])
  }

  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${aws_s3_bucket.consolidated_logs.arn}/*"]
    condition {
      test     = "StringLikeIfExists"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms", "AES256"]
    }
    condition {
      test     = "StringLikeIfExists"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.consolidated_logs_s3_bucket_cmk.arn]
    }
  }

  statement {
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.logging_s3_bucket_cmk.arn]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${local.region}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [for b in values(local.source_buckets) : "${b.arn}/*"]
    }
  }

  statement {
    actions   = ["kms:Encrypt"]
    resources = [aws_kms_key.consolidated_logs_s3_bucket_cmk.arn]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${local.region}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${aws_s3_bucket.consolidated_logs.arn}/*"]
    }
  }
}

resource "aws_iam_role_policy" "consolidated_logs_replication" {
  name   = "AllowReplicationAccess"
  role   = aws_iam_role.consolidated_logs_replication.id
  policy = data.aws_iam_policy_document.consolidated_logs_replication.json
}
