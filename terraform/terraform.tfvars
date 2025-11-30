# Terraform Configuration for shehuj.com

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
# Note: Set to empty to deploy without custom domain (use CloudFront default URL)
# After ACM certificate is issued, uncomment and add certificate ARN below
custom_domain = ""

# ACM Certificate ARN
# Note: Required when using custom_domain
# Step 1: Request certificate, Step 2: Validate via DNS, Step 3: Add ARN here
acm_certificate_arn = ""

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
