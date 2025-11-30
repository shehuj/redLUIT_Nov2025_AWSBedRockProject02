# Terraform Configuration for www.jenom.com

# AWS Configuration
aws_region     = "us-east-1"
aws_account_id = "615299732970"
environment    = "prod"

# S3 Bucket Configuration
bucket_name      = "milestone02-bedrock-website-bucket"
site_bucket_name = "milestone02-bedrock-website-bucket"

# GitHub Actions OIDC Configuration
github_repo = "redLUIT/redLUIT_Nov2025_AWSBedRockProject02"

# Terraform State Backend
tfstate_bucket      = "ec2-shutdown-lambda-bucket"
tfstate_key         = "bedrock-project02/prod/terraform.tfstate"
dynamodb_lock_table = "dyning_table"

# ============================================================================
# CUSTOM DOMAIN CONFIGURATION
# ============================================================================

# Custom Domain for CloudFront
custom_domain = "www.jenom.com"

# ACM Certificate ARN (NEWLY CREATED - WAITING FOR DNS VALIDATION)
# Certificate created: 2025-11-30
acm_certificate_arn = "arn:aws:acm:us-east-1:615299732970:certificate/b3c357ad-2711-42f8-9190-bff6a42fd45a"

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
