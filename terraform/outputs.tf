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

# Route53 DNS Outputs
output "route53_zone_id" {
  description = "Route53 hosted zone ID for custom domain"
  value       = var.custom_domain != "" ? data.aws_route53_zone.primary.zone_id : "No custom domain configured"
}

output "route53_zone_name" {
  description = "Route53 hosted zone name"
  value       = var.custom_domain != "" ? data.aws_route53_zone.primary.name : "No custom domain configured"
}

output "custom_domain_url" {
  description = "Custom domain URL (HTTPS)"
  value       = var.custom_domain != "" ? "https://${var.custom_domain}" : "No custom domain configured"
}

output "dns_records_created" {
  description = "DNS records created for custom domain"
  value = var.enable_cloudfront && var.custom_domain != "" ? {
    a_record    = "${var.custom_domain} -> ${module.cloudfront[0].distribution_domain_name} (IPv4)"
    aaaa_record = "${var.custom_domain} -> ${module.cloudfront[0].distribution_domain_name} (IPv6)"
  } : {}
}