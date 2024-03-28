# Media Bucket
resource "aws_s3_bucket" "media_bucket" {
  bucket = "${module.namespace.namespace}-media-bucket"

  tags = module.namespace.tags
}

# bucket policy
resource "aws_s3_bucket_policy" "allow_cloudfront_and_public_access" {
  bucket = aws_s3_bucket.media_bucket.id
  policy = data.aws_iam_policy_document.allow_cloudfront_and_public_access.json
}

data "aws_iam_policy_document" "allow_cloudfront_and_public_access" {
  statement {
    sid = "PublicReadGetObject"
    effect = "Allow"
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.media_bucket.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
#   statement {
#     sid = "PolicyForCloudFront"
#     effect = "Allow"
#     actions = ["s3:GetObject"]
#     resources = ["${aws_s3_bucket.media_bucket.arn}/*"]
#     principals {
#       type        = "AWS"
#       identifiers = ["cloudfront arn"]
#     }
#   }
}

# public bucket config
# resource "aws_s3_bucket_public_access_block" "enable_block" {
#   bucket = aws_s3_bucket.media_bucket.id

#   block_public_acls       = false
#   block_public_policy     = true
#   ignore_public_acls      = false
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_ownership_controls" "ownership" {
#   bucket = aws_s3_bucket.media_bucket.id
#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
#   depends_on = [aws_s3_bucket_public_access_block.enable_block]
# }

# # resource "aws_s3_bucket_acl" "bucket_acl" {
# #   depends_on = [
# #     aws_s3_bucket_ownership_controls.ownership
# #   ]

# #   bucket = aws_s3_bucket.media_bucket.id
# #   acl    = "public-read"
# # }

# Code Bucket
resource "aws_s3_bucket" "alb_logs_bucket" {
  bucket = "${module.namespace.namespace}-alb-logs"
  tags = module.namespace.tags
}

resource "aws_s3_bucket_policy" "alb_logs_bucket_policy" {
  bucket = aws_s3_bucket.alb_logs_bucket.id
  policy = data.aws_iam_policy_document.policy_doc.json
}

data "aws_iam_policy_document" "policy_doc" {
  statement {
    sid       = "AllowELBRootAccount"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.alb_logs_bucket.arn}/*"]
    actions   = ["s3:PutObject"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::127311923021:root"]
    }
  }
  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.alb_logs_bucket.arn}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
  statement {
    sid       = "AWSLogDeliveryAclCheck"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.alb_logs_bucket.arn}"]
    actions   = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}