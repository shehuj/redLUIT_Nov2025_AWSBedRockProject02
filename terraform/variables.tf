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

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, beta, prod)"
  default = "prod"
}
variable "site_bucket_name" {
  description = "S3 bucket for website / static files"
  type        = string
  default     = "captains-bucket01312025"
}

variable "tfstate_bucket" {
  description = "S3 bucket for Terraform state (if using remote backend)"
  type        = string
  default = "ec2-shutdown-lambda-bucket"
}

variable "tfstate_key" {
  description = "Key/path prefix for terraform state in the tfstate bucket"
  type        = string
  default = "bedrock-project02/prod/terraform.tfstate"
}

variable "dynamodb_lock_table" {
  description = "DynamoDB table name for state locking"
  type        = string
  default = "dyning_table"
  # optional default or specify in tfvars
}