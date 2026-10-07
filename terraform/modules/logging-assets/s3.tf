#
# Consolidated logs bucket (replication target for the cloudtrail / config / flow-logs buckets)
#

# DeletionPolicy: Retain in source template
resource "aws_s3_bucket" "consolidated_logs" {
  bucket = local.consolidated_logs_bucket_name
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "consolidated_logs" {
  bucket                  = aws_s3_bucket.consolidated_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "consolidated_logs" {
  bucket = aws_s3_bucket.consolidated_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "consolidated_logs" {
  bucket = aws_s3_bucket.consolidated_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_alias.consolidated_logs_s3_bucket_cmk.name
    }
  }
}

data "aws_iam_policy_document" "consolidated_logs_bucket" {
  statement {
    sid = "AllowOrganizationAccess"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]
    resources = [
      aws_s3_bucket.consolidated_logs.arn,
      "${aws_s3_bucket.consolidated_logs.arn}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.principal_org_id]
    }
  }
}

resource "aws_s3_bucket_policy" "consolidated_logs" {
  bucket = aws_s3_bucket.consolidated_logs.id
  policy = data.aws_iam_policy_document.consolidated_logs_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.consolidated_logs]
}

#
# Source log buckets: cloudtrail, config, flow-logs
#

# DeletionPolicy: Retain in source template
resource "aws_s3_bucket" "cloudtrail" {
  bucket = local.cloudtrail_bucket_name
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [aws_s3_bucket.consolidated_logs]
}

# DeletionPolicy: Retain in source template
resource "aws_s3_bucket" "config" {
  bucket = local.config_bucket_name
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [aws_s3_bucket.consolidated_logs]
}

# DeletionPolicy: Retain in source template
resource "aws_s3_bucket" "flow_logs" {
  bucket = local.flow_logs_bucket_name
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [aws_s3_bucket.consolidated_logs]
}

resource "aws_s3_bucket_public_access_block" "source" {
  for_each = local.source_buckets

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "source" {
  for_each = local.source_buckets

  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "source" {
  for_each = local.source_buckets

  bucket = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_alias.logging_s3_bucket_cmk.arn
    }
  }
}

# Same-account replication of every source bucket into the consolidated logs bucket
resource "aws_s3_bucket_replication_configuration" "source" {
  for_each = local.source_buckets

  bucket = each.value.id
  role   = aws_iam_role.consolidated_logs_replication.arn

  rule {
    id     = "ConsolidatedLogs"
    status = "Enabled"

    # No filter block => V1 replication schema, equivalent to CFN `Prefix: ""`

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.consolidated_logs.arn
      storage_class = "STANDARD_IA"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.consolidated_logs_s3_bucket_cmk.arn
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.source,
    aws_s3_bucket_versioning.consolidated_logs,
  ]
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "DenyInsecureConnections"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid = "AWSLogDeliveryWrite"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.source]
}

data "aws_iam_policy_document" "config_bucket" {
  statement {
    sid    = "DenyInsecureConnections"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.config.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid = "AWSLogDeliveryWrite"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.config.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.config.arn]
  }

  statement {
    sid = "AWSConfigBucketExistenceCheck"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.config.arn]
  }
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id
  policy = data.aws_iam_policy_document.config_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.source]
}

data "aws_iam_policy_document" "flow_logs_bucket" {
  statement {
    sid = "AWSLogDeliveryWrite"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.flow_logs.arn}/AWSLogs/*/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.flow_logs.arn]
  }
}

resource "aws_s3_bucket_policy" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.source]
}
