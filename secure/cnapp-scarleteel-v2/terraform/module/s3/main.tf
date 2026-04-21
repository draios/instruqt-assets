#-------module/s3/main.tf
resource "aws_s3_bucket" "s3_bucket" {
  bucket_prefix = var.bucket_name
  tags = {
    Name = "bucket"
  }
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.s3_bucket.bucket
  key    = var.object_key
  source = var.object_source
}
resource "aws_s3_bucket_public_access_block" "project" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
