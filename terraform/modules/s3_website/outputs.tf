output "bucket_id" {
  value = aws_s3_bucket.this.id
}

output "website_endpoint" {
  value = aws_s3_bucket.this.website_endpoint
}