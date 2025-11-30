variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name for resume website"
  type        = string
  default     = "milestone02-bedrock-website-bucket"
}

variable "github_repo" {
  description = "GitHub repo name (org/repo) for OIDC role"
  type        = string
  default     = "redLUIT/redLUIT_Nov2025_AWSBedRockProject02"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "615299732970"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, beta, prod)"
  default     = "prod"
}
variable "site_bucket_name" {
  description = "S3 bucket for website / static files"
  type        = string
  default     = "milestone02-bedrock-website-bucket"
}

variable "tfstate_bucket" {
  description = "S3 bucket for Terraform state (if using remote backend)"
  type        = string
  default     = "ec2-shutdown-lambda-bucket"
}

variable "tfstate_key" {
  description = "Key/path prefix for terraform state in the tfstate bucket"
  type        = string
  default     = "bedrock-project02/prod/terraform.tfstate"
}

variable "dynamodb_lock_table" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "dyning_table"
}

# CloudFront Configuration
# CloudFront is REQUIRED - S3 bucket is private and only accessible via CloudFront OAC
variable "enable_cloudfront" {
  description = "Enable CloudFront distribution (REQUIRED for access - S3 bucket is private)"
  type        = bool
  default     = true

  validation {
    condition     = var.enable_cloudfront == true
    error_message = "CloudFront must be enabled. S3 bucket is private and only accessible via CloudFront Origin Access Control (OAC)."
  }
}

variable "cloudfront_price_class" {
  description = "CloudFront price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
}

variable "custom_domain" {
  description = "Custom domain name for CloudFront (optional)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for custom domain (must be in us-east-1)"
  type        = string
  default     = ""
}

variable "geo_restriction_type" {
  description = "Type of geo restriction (none, whitelist, blacklist)"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "enable_cloudfront_logging" {
  description = "Enable CloudFront access logging"
  type        = bool
  default     = false
}

variable "cloudfront_logging_bucket" {
  description = "S3 bucket for CloudFront logs"
  type        = string
  default     = ""
}

variable "cloudfront_logging_prefix" {
  description = "Prefix for CloudFront log files"
  type        = string
  default     = "cloudfront-logs/"
}

variable "web_acl_id" {
  description = "AWS WAF Web ACL ID for CloudFront (optional)"
  type        = string
  default     = ""
}