output "bucket_name" {
  description = "S3 bucket name"
  value       = module.site_bucket.bucket_id
}

output "s3_website_endpoint" {
  description = "S3 website endpoint (HTTP only)"
  value       = module.site_bucket.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = var.enable_cloudfront ? module.cloudfront[0].distribution_id : "CloudFront not enabled"
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = var.enable_cloudfront ? module.cloudfront[0].distribution_domain_name : "CloudFront not enabled"
}

output "website_url" {
  description = "Primary website URL (CloudFront if enabled, S3 otherwise)"
  value       = var.enable_cloudfront ? module.cloudfront[0].cloudfront_url : "http://${module.site_bucket.website_endpoint}"
}

output "deployment_tracking_table_name" {
  description = "DynamoDB deployment tracking table name"
  value       = module.deployment_tracking_table.table_name
}

output "resume_analytics_table_name" {
  description = "DynamoDB resume analytics table name"
  value       = module.resume_analytics_table.table_name
}