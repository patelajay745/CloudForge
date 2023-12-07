resource "aws_s3_bucket" "s3-bucket" {
  bucket        = var.bucket-name
  
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
}
#by adding force destroy , it won't throw error "bucket is not empty" while destroying it

#null resource will push all the files in one time instead of sending all files one by one
resource "null_resource" "upload-to-s3" {
  provisioner "local-exec" {
    command = "aws s3 sync ${path.module}/../website s3://${aws_s3_bucket.s3-bucket.id}"

  }

}

#to make bucket private
resource "aws_s3_bucket_public_access_block" "website_bucket_access" {

  bucket                  = aws_s3_bucket.s3-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}


#IAM policy for an S3 bucket that allows CloudFront to access its content
data "aws_iam_policy_document" "website_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3-bucket.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.cdn_static_website.arn]
    }
  }

}

#attaching policy to bucket
resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.s3-bucket.id
  policy = data.aws_iam_policy_document.website_bucket.json

}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.s3-bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
