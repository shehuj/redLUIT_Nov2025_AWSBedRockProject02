# CloudFront Module Variables

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "bucket_id" {
  description = "ID of the S3 bucket"
  type        = string
}

variable "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name (prod, beta, dev)"
  type        = string
  default     = "prod"
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100" # US, Canada, Europe
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

variable "enable_logging" {
  description = "Enable CloudFront access logging"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "S3 bucket for CloudFront logs (must end with .s3.amazonaws.com)"
  type        = string
  default     = ""
}

variable "logging_prefix" {
  description = "Prefix for CloudFront log files"
  type        = string
  default     = "cloudfront-logs/"
}

variable "web_acl_id" {
  description = "AWS WAF Web ACL ID for CloudFront (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for CloudFront resources"
  type        = map(string)
  default     = {}
}
