# environments/dev.tfvars

# AWS region
aws_region = "us-east-1"

# Example: S3 bucket for storing website / state / assets
# (replace with your actual bucket)
site_bucket_name = "captains-bucket01312025"

# Example: prefix/key for Terraform state in S3 backend
tfstate_key = "envs/dev/terraform.tfstate"
tfstate_bucket = "ec2-shutdown-lambda-bucket"

# Example: DynamoDB lock table name (if you use one)
dynamodb_lock_table = "dyning_table"

# Example: Environment tag or name
environment = "dev"

# Add other variables used in your Terraform config below:
# e.g.
# vpc_cidr = "10.0.0.0/16"
# public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
# instance_type = "t3.medium"
# allowed_ips = ["1.2.3.4/32"]