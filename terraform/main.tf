module "site_bucket" {
  source      = "./modules/s3_website"
  bucket_name = var.bucket_name

  tags = {
    Project     = "Resume-Generator"
    Environment = var.environment
  }
}

module "cloudfront" {
  count  = var.enable_cloudfront ? 1 : 0
  source = "./modules/cloudfront"

  bucket_name                  = module.site_bucket.bucket_id
  bucket_id                    = module.site_bucket.bucket_id
  bucket_regional_domain_name  = module.site_bucket.bucket_regional_domain_name
  environment                  = var.environment
  price_class                  = var.cloudfront_price_class
  custom_domain                = var.custom_domain
  acm_certificate_arn          = var.acm_certificate_arn
  geo_restriction_type         = var.geo_restriction_type
  geo_restriction_locations    = var.geo_restriction_locations
  enable_logging               = var.enable_cloudfront_logging
  logging_bucket               = var.cloudfront_logging_bucket
  logging_prefix               = var.cloudfront_logging_prefix
  web_acl_id                   = var.web_acl_id

  tags = {
    Project = "Resume-Generator"
  }
}

module "deployment_tracking_table" {
  source        = "./modules/dynamodb_table"
  table_name    = "DeploymentTracking"
  hash_key_name = "CommitSHA"
}

module "resume_analytics_table" {
  source        = "./modules/dynamodb_table"
  table_name    = "ResumeAnalytics"
  hash_key_name = "ResumeID"
}

module "github_actions_iam" {
  source         = "./modules/iam_for_github_actions"
  role_name      = "github-actions-resume-role"
  environment    = "prod"
  s3_bucket      = var.bucket_name
  aws_account_id = "615299732970"
  region         = var.aws_region
  github_repo    = var.github_repo
}