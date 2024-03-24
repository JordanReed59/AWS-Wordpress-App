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
resource "aws_s3_bucket_public_access_block" "enable_block" {
  bucket = aws_s3_bucket.media_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.media_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.ownership
  ]

  bucket = aws_s3_bucket.media_bucket.id
  acl    = "public-read"
}

# Code Bucket
resource "aws_s3_bucket" "code_bucket" {
  bucket = "${module.namespace.namespace}-code-bucket"

  tags = module.namespace.tags
}