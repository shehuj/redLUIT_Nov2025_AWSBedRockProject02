module "site_bucket" {
  source      = "./modules/s3_website"
  bucket_name = var.bucket_name
  public_read = true
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
  source      = "./modules/iam_for_github_actions"
  role_name   = "github-actions-resume-role"
  environment = "prod"
  s3_bucket   = var.bucket_name
  aws_account_id = "615299732970"
  region         = var.aws_region
  github_repo = var.github_repo
}