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