output "bucket_name" {
  value = module.site_bucket.bucket_id
}

output "website_url" {
  value = module.site_bucket.website_endpoint
}

output "deployment_tracking_table_name" {
  value = module.deployment_tracking_table.table_name
}

output "resume_analytics_table_name" {
  value = module.resume_analytics_table.table_name
}

output "github_actions_role_arn" {
  value = module.github_actions_iam.role_arn
}