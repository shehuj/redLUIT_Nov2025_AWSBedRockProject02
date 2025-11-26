variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name for resume website"
  type        = string
  default     = "captains-bucket01312025"
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