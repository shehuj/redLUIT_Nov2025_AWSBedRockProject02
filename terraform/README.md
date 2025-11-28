# Terraform Infrastructure

> **📖 For complete project documentation, see the [main README](../README.md) in the project root.**

This directory contains the Terraform infrastructure-as-code configuration for the AWS Bedrock Resume Generator project.

## Quick Start

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply infrastructure
terraform apply

# View outputs
terraform output
```

## Directory Structure

```
terraform/
├── backend.tf              # S3 backend configuration
├── main.tf                 # Root module - instantiates all modules
├── providers.tf            # AWS provider configuration
├── variables.tf            # Input variables with defaults
├── outputs.tf              # Output values
│
├── modules/               # Reusable modules
│   ├── s3_website/        # S3 static website hosting
│   ├── dynamodb_table/    # DynamoDB table creation
│   └── iam_for_github_actions/  # IAM + OIDC for GitHub
│
└── scripts/
    └── generate_and_deploy.py   # AI resume generator
```

## Resources Created

When you run `terraform apply`, this configuration creates:

| Resource | Name | Purpose |
|----------|------|---------|
| **S3 Bucket** | `var.bucket_name` | Static website hosting for resume |
| **DynamoDB Table** | `DeploymentTracking` | Track deployment history by CommitSHA |
| **DynamoDB Table** | `ResumeAnalytics` | Resume version analytics by ResumeID |
| **IAM Role** | `github-actions-resume-role` | OIDC authentication for GitHub Actions |
| **S3 Bucket Policy** | (auto) | Public read access for website |
| **S3 Website Config** | (auto) | index.html / error.html configuration |

## Configuration

### Required Variables

Edit `variables.tf` or create `terraform.tfvars`:

```hcl
aws_region       = "us-east-1"
bucket_name      = "your-unique-bucket-name"
github_repo      = "your-org/your-repo"
aws_account_id   = "123456789012"
```

### Backend Configuration

The S3 backend is configured in `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "ec2-shutdown-lambda-bucket"
    key            = "bedrock-project02/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "dyning_table"
  }
}
```

**Note**: Ensure the backend bucket and DynamoDB table exist before running `terraform init`.

## Modules

### 1. S3 Website Module

Creates S3 bucket with website hosting configuration.

```hcl
module "site_bucket" {
  source      = "./modules/s3_website"
  bucket_name = var.bucket_name
  public_read = true
}
```

**Outputs**: `bucket_id`, `website_endpoint`

### 2. DynamoDB Table Module

Creates DynamoDB tables for tracking.

```hcl
module "deployment_tracking_table" {
  source        = "./modules/dynamodb_table"
  table_name    = "DeploymentTracking"
  hash_key_name = "CommitSHA"
}
```

**Outputs**: `table_name`, `table_arn`

### 3. IAM for GitHub Actions Module

Creates IAM role with OIDC trust for GitHub Actions.

```hcl
module "github_actions_iam" {
  source         = "./modules/iam_for_github_actions"
  role_name      = "github-actions-resume-role"
  environment    = "prod"
  s3_bucket      = var.bucket_name
  aws_account_id = var.aws_account_id
  region         = var.aws_region
  github_repo    = var.github_repo
}
```

**Outputs**: `role_arn`, `role_name`

## Outputs

After applying, Terraform outputs:

```bash
bucket_name                     = "captains-bucket01312025"
website_url                     = "captains-bucket01312025.s3-website-us-east-1.amazonaws.com"
deployment_tracking_table_name  = "DeploymentTracking"
resume_analytics_table_name     = "ResumeAnalytics"
```

## Common Commands

```bash
# Format all Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# List all resources
terraform state list

# Target specific module
terraform apply -target=module.site_bucket

# Destroy all infrastructure (use with caution!)
terraform destroy
```

## Troubleshooting

### Backend Initialization Failed

```bash
# Create backend bucket
aws s3 mb s3://your-state-bucket --region us-east-1

# Create lock table
aws dynamodb create-table \
  --table-name your-lock-table \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### State Locked

```bash
terraform force-unlock <LOCK_ID>
```

### S3 Bucket Name Already Exists

S3 bucket names are globally unique. Choose a different name in `variables.tf`.

## For More Information

- **Complete Documentation**: [../README.md](../README.md)
- **Deployment Guide**: [../README.md#-deployment](../README.md#-deployment)
- **Troubleshooting**: [../README.md#-troubleshooting](../README.md#-troubleshooting)
- **Module Details**: [../README.md#-terraform-modules](../README.md#-terraform-modules)

---

**Version**: Terraform >= 1.6.0
**Provider**: AWS Provider ~> 6.0
