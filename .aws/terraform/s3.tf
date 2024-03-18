# Media Bucket
resource "aws_s3_bucket" "media_bucket" {
  bucket = "${module.namespace.namespace}-media-bucket"

  tags = module.namespace.tags
}

# bucket policy
resource "aws_s3_bucket_policy" "allow_cloudfront_and_public_access" {
  bucket = aws_s3_bucket.media_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_cloudfront_and_public_access" {
  statement {
    sid = "PublicReadGetObject"
    effect = "Allow"
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.media_bucket.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = "*"
    }
  }
#   statement {
#     sid = "PolicyForCloudFront"
#     effect = "Allow"
#     actions = ["s3:GetObject"]
#     resources = ["${aws_s3_bucket.media_bucket.arn}/*"]
#     principals {
#       type        = "AWS"
#       identifiers = "*"
#     }
#   }
}

# public bucket config
resource "aws_s3_bucket_public_access_block" "disable_block" {
  bucket = aws_s3_bucket.media_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [
    aws_s3_bucket_public_access_block.disable_block
  ]

  bucket = aws_s3_bucket.media_bucket.id
  acl    = "public-read"
}

# Code Bucket
resource "aws_s3_bucket" "code_bucket" {
  bucket = "${module.namespace.namespace}-code-bucket"

  tags = module.namespace.tags
}