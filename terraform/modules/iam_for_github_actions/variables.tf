variable "role_name" {
  description = "Name of the IAM role for GitHub Actions"
  type        = string
  default     = "redLUIT_GitHubActions_Role_${ gitbub_refpo }"
}

variable "github_repo" {
  description = "GitHub repo in format org/repo (for OIDC condition)"
  type        = string
  default     = "redLUIT/redLUIT_Nov2025_AWSBedRockProject02"
}

variable "region" {
  description = "AWS region for the IAM role"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS Account ID where the IAM role will be created"
  type        = string
  default     = "615299732970"
}

variable "s3_bucket" {
  description = "S3 bucket name for GitHub Actions to access"
  type        = string
  default     = "captains-bucket01312025"
}
