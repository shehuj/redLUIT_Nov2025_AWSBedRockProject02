/*
## Set Environment-specific variables for the prod environment
# environment attribute removed as it is not valid in this context
# region attribute removed as it is not valid in this context
# instance_type attribute removed as it is not valid in this context
# scaling_enabled attribute removed as it is not valid in this context
# environments/prod.tfvars

# ===== Global / general settings =====

aws_region  = "us-east-1" # ← Change to your production AWS region
environment = "prod"

# ===== S3 / Website / Static Hosting =====

# Bucket for website, resume HTML, assets, etc.
site_bucket_name = "captains-bucket01312025" # ← Replace with your real production bucket
# If you use the bucket for terraform state as well (not recommended for prod), set accordingly
tfstate_bucket      = "ec2-shutdown-lambda-bucket"  # ← optional / if you use S3 backend
key         = "bedrock-project02/prod/terraform.tfstate"
dynamodb_lock_table = "dyning_table"                # if you use DynamoDB locking

# ===== Networking / VPC / Subnets / Security =====
# (uncomment and fill in if your config expects these)

# vpc_cidr = "10.0.0.0/16"
# public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
# private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
# availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# ===== EC2 / Instance Settings =====
# instance_type = "m5.large"
# ssh_key_name = "my-prod-ssh-key"
# ami_id = "ami-0abcdef12345..."

# ===== Tags / Metadata =====
tags = {
  Environment = "prod"
  Project     = "redLUIT"
  Owner       = "SRE"
}

# ===== Optional / Feature Flags =====
enable_monitoring = true # if you enable Prometheus / CloudWatch / logging by default
enable_backup     = true # if your databases/storage needs backups
enable_ssl        = true # if using SSL / HTTPS on website or services

# ===== Other variables specific to your modules =====
# ... add more as needed, e.g. database settings, lambda names, etc.
*/

# Terraform Configuration for shehuj.com

# AWS Configuration
aws_region     = "us-east-1"
aws_account_id = "615299732970"
environment    = "prod"

# S3 Bucket Configuration
bucket_name      = "milestone02-bedrock-website-bucket"
site_bucket_name = "milestone02-bedrock-website-bucket"

# GitHub Actions OIDC Configuration
github_repo = "shehuj/redLUIT_Nov2025_AWSBedRockProject02"

# Terraform State Backend
tfstate_bucket      = "ec2-shutdown-lambda-bucket"
tfstate_key         = "bedrock-project02/prod/terraform.tfstate"
dynamodb_lock_table = "dyning_table"

# ============================================================================
# CUSTOM DOMAIN CONFIGURATION
# ============================================================================

# Custom Domain for CloudFront
custom_domain = "shehuj.com"

# ACM Certificate ARN (ISSUED and ready to use)
# Certificate validated via Route53 DNS
# Domain: shehuj.com
acm_certificate_arn = "arn:aws:acm:us-east-1:615299732970:certificate/a945df0b-6ad5-4de5-a1ed-a9a04cdaea62"

# ============================================================================
# CLOUDFRONT CONFIGURATION
# ============================================================================

# CloudFront is REQUIRED (S3 bucket is private - CloudFront-only access)
enable_cloudfront = true

# CloudFront Price Class (PriceClass_100 = US, Canada, Europe)
cloudfront_price_class = "PriceClass_100"

# Geographic Restrictions
geo_restriction_type      = "none"
geo_restriction_locations = []

# ============================================================================
# CLOUDFRONT LOGGING (Optional)
# ============================================================================

enable_cloudfront_logging = false
cloudfront_logging_bucket = ""
cloudfront_logging_prefix = "cloudfront-logs/"

# ============================================================================
# WAF CONFIGURATION (Optional)
# ============================================================================

web_acl_id = ""
