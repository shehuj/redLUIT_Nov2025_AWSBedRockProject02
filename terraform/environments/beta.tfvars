/*
## Set environment-specific variables for the beta environment
environment     = "beta"
region          = "us-west-2"
instance_type   = "t3.medium"
scaling_enabled = true
max_instances   = 5
min_instances   = 1  
*/ # environments/beta.tfvars

# --- Global / general settings ---
aws_region  = "us-east-1" # Change to your target AWS region for beta
environment = "beta"

# --- S3 / Website / Static Hosting / State (if used) ---
site_bucket_name    = "captains-bucket01312025"     # ← Replace with your beta bucket name
tfstate_bucket      = "ec2-shutdown-lambda-bucket"  # Optional: bucket for terraform state if separate
key         = "bedrock-project02/beta/terraform.tfstate"
dynamodb_lock_table = "dyning_table"                # If using DynamoDB locking backend

# --- Tags / Metadata ---
tags = {
  Environment = "beta"
  Project     = "redLUIT"
  Stage       = "beta"
}

# --- Feature Flags / Optional Settings (customize as needed) ---
enable_monitoring = false # maybe disable monitoring in beta environment
enable_backup     = false # disable backups in beta if not needed
enable_ssl        = false # adjust depending on staging/ssl setup

# --- Example module-specific or resource-specific overrides ---
# (Uncomment / add as needed based on your Terraform variable definitions)
# instance_type     = "t3.medium"
# public_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
# private_subnets   = ["10.0.10.0/24", "10.0.11.0/24"]
# allowed_ips       = ["203.0.113.0/32"]
# db_instance_class = "db.t3.micro"
# ssh_key_name      = "beta-ssh-key"
# extra_tags        = { "CostCenter" = "BetaTest" }