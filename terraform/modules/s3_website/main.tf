resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  versioning {
    enabled = var.enable_versioning
  }

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.this.id

  # Allow bucket policy to grant public read
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false  # must allow policies
  restrict_public_buckets = false  # allow bucket policy
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
      }
    ]
  })
}