# AWS Bedrock AI-Powered Resume Generator & Deployment System

[![Deploy Terraform Prod](https://github.com/shehuj/redLUIT_Nov2025_AWSBedRockProject02/actions/workflows/deploy_prod.yml/badge.svg)](https://github.com/shehuj/redLUIT_Nov2025_AWSBedRockProject02/actions/workflows/deploy_prod.yml)
[![Deploy Terraform NPE](https://github.com/shehuj/redLUIT_Nov2025_AWSBedRockProject02/actions/workflows/deploy_npe.yml/badge.svg)](https://github.com/shehuj/redLUIT_Nov2025_AWSBedRockProject02/actions/workflows/deploy_npe.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An intelligent, fully automated resume generation and deployment system that leverages AWS Bedrock's Claude AI models to transform markdown resumes into beautiful, ATS-friendly HTML websites. Built with infrastructure-as-code principles using Terraform and automated via GitHub Actions CI/CD pipelines.

**Part of the Level Up In Tech (LUIT) November 2025 Cohort - AWS Bedrock Project 02**

## 🚀 Project Overview

This project showcases a production-ready, enterprise-grade CI/CD pipeline that:

- **AI-Powered Generation**: Utilizes AWS Bedrock Claude 3.5 Sonnet/Haiku models with intelligent fallback to inference profiles for optimal availability
- **Static Website Hosting**: Automatically deploys generated HTML resumes to S3 with public website configuration
- **Infrastructure as Code**: Complete Terraform implementation with reusable, modular architecture
- **Multi-Environment Support**: Separate workflows for production (`main` branch) and non-production environments (`beta`, `dev` branches)
- **Deployment Tracking**: DynamoDB tables for tracking deployments and analytics
- **Security Best Practices**:
  - IAM roles with least-privilege policies
  - Encrypted Terraform state with S3 backend
  - State locking with DynamoDB
  - GitHub Actions OIDC authentication
  - Secure secret management

## 🏗️ System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                          │
│  ┌────────────────┐    ┌──────────────────┐                     │
│  │ resume_       │    │ terraform/       │                     │
│  │ template.md   │    │ modules/         │                     │
│  └────────────────┘    └──────────────────┘                     │
└───────────────┬──────────────────┬───────────────────────────────┘
                │                  │
        Push to main/beta     Pull Request
                │                  │
                ▼                  ▼
    ┌─────────────────────────────────────────┐
    │      GitHub Actions Workflows           │
    │  ┌──────────────┐  ┌─────────────────┐ │
    │  │ deploy_prod  │  │  deploy_npe     │ │
    │  │ (main)       │  │  (beta/dev)     │ │
    │  └──────┬───────┘  └────────┬────────┘ │
    └─────────┼──────────────────┬─┼──────────┘
              │                  │ │
              ▼                  ▼ ▼
    ┌──────────────────┐   ┌────────────────┐
    │  AWS Credentials │   │  Terraform     │
    │  (Secrets/OIDC)  │   │  Init/Plan     │
    └──────────────────┘   └────────┬───────┘
                                    │
                   ┌────────────────┼────────────────┐
                   │                │                │
                   ▼                ▼                ▼
         ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
         │ S3 Module    │  │ DynamoDB     │  │ IAM Module   │
         │ (Website)    │  │ Module (x2)  │  │ (GH Actions) │
         └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
                │                 │                  │
                ▼                 ▼                  ▼
         ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
         │  S3 Bucket   │  │  DynamoDB    │  │  IAM Role    │
         │  + Website   │  │  Tables:     │  │  + Policy    │
         │  Config      │  │  - Tracking  │  │              │
         │              │  │  - Analytics │  │              │
         └──────────────┘  └──────────────┘  └──────────────┘
                │
                ▼
    ┌────────────────────────────┐
    │ generate_and_deploy.py     │
    │                            │
    │ 1. Read resume_template.md │
    │ 2. Call Bedrock API        │
    │ 3. Upload HTML to S3       │
    └───────────┬────────────────┘
                │
                ▼
    ┌────────────────────────────┐
    │    AWS Bedrock Runtime     │
    │  ┌──────────────────────┐  │
    │  │ Try Foundation Model:│  │
    │  │ - Claude 3.5 Sonnet  │  │
    │  │ - Claude 3.5 Haiku   │  │
    │  │ - Claude 3 Sonnet    │  │
    │  └──────────────────────┘  │
    │           │ Fallback        │
    │           ▼                 │
    │  ┌──────────────────────┐  │
    │  │ Inference Profile    │  │
    │  │ (Auto-discovered)    │  │
    │  └──────────────────────┘  │
    └────────────┬───────────────┘
                 │
                 ▼ (HTML Content)
    ┌────────────────────────────┐
    │    S3 Bucket (Website)     │
    │    index.html / {env}/     │
    │    Public Read Access      │
    └────────────┬───────────────┘
                 │
                 ▼
         📄 Live Resume Website
            (S3 Website Endpoint)
```

### Architecture Highlights

1. **Dual Workflow Strategy**:
   - `deploy_prod.yml`: Triggered on push to `main` - deploys to production
   - `deploy_npe.yml`: Triggered on PR to `main`/`beta`/`dev` - validates and deploys to test environments

2. **Intelligent AI Model Selection**:
   - Attempts multiple Claude models in priority order
   - Automatic fallback to inference profiles if foundation models hit throughput limits
   - Dynamic profile discovery via Bedrock management API

3. **Terraform State Management**:
   - Remote backend in S3 (`ec2-shutdown-lambda-bucket`)
   - State locking via DynamoDB (`dyning_table`)
   - Encrypted at rest for security

## 📋 Key Features

### 🤖 AI-Powered Resume Generation
- **Multiple Model Support**: Automatically tries Claude 3.5 Sonnet, Claude 3.5 Haiku, and Claude 3 Sonnet
- **Intelligent Fallback**: Auto-discovers and uses inference profiles when foundation models are unavailable
- **Customizable Prompts**: Generate professional, ATS-friendly HTML with modern design
- **Error Handling**: Comprehensive error handling with detailed troubleshooting guidance

### 🚀 Multi-Environment CI/CD
- **Production Workflow** (`deploy_prod.yml`):
  - Triggers on push to `main` branch
  - Python 3.12 runtime
  - Full Terraform deployment
  - Automated resume generation and S3 upload
  - Environment-specific S3 prefixing (`prod/`)

- **Non-Production Workflow** (`deploy_npe.yml`):
  - Triggers on pull requests to `main`, `beta`, `dev`
  - Terraform plan and validation
  - Conditional apply on `beta` branch
  - Post-deployment Python script execution

### 🏗️ Infrastructure as Code
- **Modular Terraform Architecture**:
  - `s3_website`: Static website hosting with public access policies
  - `dynamodb_table`: Reusable table module for state locking and application data
  - `iam_for_github_actions`: OIDC-based IAM role for secure GitHub Actions authentication

- **Resource Management**:
  - S3 bucket versioning support
  - Website configuration (index.html, error.html)
  - Public read policies with explicit public access block configuration
  - DynamoDB tables: `DeploymentTracking`, `ResumeAnalytics`

### 🔒 Security & Best Practices
- **Encrypted State**: Terraform state encrypted in S3 with DynamoDB locking
- **IAM Best Practices**: Least-privilege roles with specific S3 and Bedrock permissions
- **Secret Management**: GitHub secrets for AWS credentials and configuration
- **Code Quality**: Pre-commit hooks with Terraform fmt, Python flake8, Markdown linting

### 📊 Deployment Tracking
- **DeploymentTracking Table**: Hash key on `CommitSHA` for tracking deployments
- **ResumeAnalytics Table**: Hash key on `ResumeID` for analytics and versioning

## 🛠️ Technology Stack

### Cloud Infrastructure
| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Compute** | AWS Bedrock (Claude AI) | AI-powered HTML generation |
| **Storage** | Amazon S3 | Static website hosting, Terraform state |
| **Database** | Amazon DynamoDB | State locking, deployment tracking, analytics |
| **IAM** | AWS IAM + OIDC | Secure GitHub Actions authentication |
| **IaC** | Terraform 1.6.0 | Infrastructure provisioning and management |

### Application Stack
| Layer | Technology | Version |
|-------|-----------|---------|
| **Language** | Python | 3.12 |
| **AWS SDK** | boto3 | >=1.26.0 |
| **AWS Core** | botocore | Latest |
| **HTTP Client** | urllib3 | >=1.26.16 |
| **Markdown** | markdown2 | Latest |

### CI/CD Pipeline
- **Platform**: GitHub Actions
- **Workflows**:
  - `deploy_prod.yml` - Production deployment
  - `deploy_npe.yml` - Non-production environments
- **Actions Used**:
  - `actions/checkout@v4`
  - `actions/setup-python@v3`
  - `hashicorp/setup-terraform@v3`
  - `aws-actions/configure-aws-credentials@v5`

### Development Tools
- **Code Quality**: Pre-commit hooks, flake8, Terraform fmt/validate
- **Version Control**: Git with branch-based deployments
- **Testing**: Terraform plan validation, Python linting

## 📁 Project Structure

```
redLUIT_Nov2025_AWSBedRockProject02/
│
├── .github/
│   └── workflows/
│       ├── deploy_prod.yml           # Production deployment (main branch)
│       └── deploy_npe.yml            # Non-production deployment (PR to beta/dev)
│
├── terraform/                        # Terraform root module
│   ├── backend.tf                    # S3 backend configuration
│   ├── main.tf                       # Main infrastructure definitions
│   ├── providers.tf                  # AWS provider configuration
│   ├── variables.tf                  # Input variables with defaults
│   ├── outputs.tf                    # Output values (bucket, URLs, tables)
│   │
│   ├── modules/                      # Reusable Terraform modules
│   │   ├── s3_website/               # S3 static website module
│   │   │   ├── main.tf               # S3 bucket, versioning, website config
│   │   │   ├── variables.tf          # Module inputs
│   │   │   └── outputs.tf            # Bucket ID, website endpoint
│   │   │
│   │   ├── dynamodb_table/           # DynamoDB table module
│   │   │   ├── main.tf               # Table with configurable hash key
│   │   │   ├── variables.tf          # Table name, hash key, billing mode
│   │   │   └── outputs.tf            # Table name, ARN
│   │   │
│   │   └── iam_for_github_actions/   # IAM + OIDC module
│   │       ├── main.tf               # IAM role, OIDC provider, policies
│   │       ├── variables.tf          # GitHub org/repo, role name
│   │       └── outputs.tf            # Role ARN, name
│   │
│   └── scripts/
│       └── generate_and_deploy.py    # AI resume generator script
│
├── tests/                            # Test files (if any)
│
├── resume_template.md                # Markdown resume template
├── resume.html                       # Generated HTML resume (local)
├── requirements.txt                  # Python dependencies
├── .pre-commit-config.yaml           # Pre-commit hooks config
├── .flake8                           # Python linting configuration
├── .mardownlint.json                 # Markdown linting rules
├── .gitignore                        # Git ignore patterns
├── LICENSE                           # MIT License
└── README.md                         # This file
```

### Key Files Explained

| File/Directory | Description |
|----------------|-------------|
| `terraform/backend.tf` | Configures S3 backend for state storage with encryption and DynamoDB locking |
| `terraform/main.tf` | Instantiates modules: S3 website, 2x DynamoDB tables, IAM role |
| `terraform/variables.tf` | Defines variables: AWS region, bucket names, GitHub repo, account ID |
| `terraform/outputs.tf` | Exports bucket ID, website URL, DynamoDB table names |
| `terraform/scripts/generate_and_deploy.py` | Python script that calls Bedrock API and uploads to S3 |
| `.github/workflows/deploy_prod.yml` | Production CI/CD: Terraform apply + AI generation on main push |
| `.github/workflows/deploy_npe.yml` | NPE CI/CD: Terraform plan on PR, apply on beta |
| `resume_template.md` | Source markdown file for resume content |
| `requirements.txt` | boto3, botocore, urllib3, markdown2 |

## 🚦 Getting Started

### Prerequisites

Before you begin, ensure you have the following:

| Requirement | Version | Purpose |
|------------|---------|---------|
| **AWS Account** | - | With Bedrock model access enabled |
| **Terraform** | >= 1.6.0 | Infrastructure provisioning |
| **Python** | >= 3.12 | Script execution |
| **AWS CLI** | >= 2.x | Local AWS configuration |
| **GitHub Account** | - | Repository and Actions |
| **Git** | >= 2.x | Version control |

### AWS Bedrock Model Access

**IMPORTANT**: You must enable AWS Bedrock model access before deployment:

1. Navigate to [AWS Bedrock Console](https://console.aws.amazon.com/bedrock/)
2. Go to **Model access**
3. Request access to the following models:
   - Claude 3.5 Sonnet
   - Claude 3.5 Haiku
   - Claude 3 Sonnet
4. Wait for approval (usually instant for base models)

### Installation

#### 1. Clone the Repository
```bash
git clone https://github.com/shehuj/redLUIT_Nov2025_AWSBedRockProject02.git
cd redLUIT_Nov2025_AWSBedRockProject02
```

#### 2. Install Python Dependencies
```bash
pip install -r requirements.txt
```

The `requirements.txt` includes:
- `boto3>=1.26.0` - AWS SDK for Python
- `botocore` - Low-level AWS interface
- `urllib3>=1.26.16` - HTTP client
- `markdown2` - Markdown parsing

#### 3. Configure AWS Credentials Locally

**Option A: AWS CLI Configuration**
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

**Option B: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

#### 4. (Optional) Install Pre-commit Hooks
```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files  # Test the hooks
```

### Configuration

#### 1. Set Up GitHub Secrets

Navigate to **Repository Settings > Secrets and variables > Actions** and add:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | AWS access key for GitHub Actions | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | AWS deployment region | `us-east-1` |
| `RESUME_BUCKET` | S3 bucket for resume hosting | `captains-bucket01312025` |

#### 2. Configure Terraform Backend

Edit `terraform/backend.tf` to use your state storage:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"    # Change this
    key            = "bedrock-project02/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "your-state-lock-table"          # Change this
  }
}
```

**Note**: Ensure the S3 bucket and DynamoDB table exist before running `terraform init`.

#### 3. Update Terraform Variables

Edit `terraform/variables.tf` or create `terraform.tfvars`:

```hcl
# terraform/terraform.tfvars
aws_region       = "us-east-1"
bucket_name      = "your-unique-resume-bucket-name"
github_repo      = "your-org/your-repo-name"
aws_account_id   = "123456789012"
environment      = "prod"
site_bucket_name = "your-unique-resume-bucket-name"
tfstate_bucket   = "your-terraform-state-bucket"
tfstate_key      = "bedrock-project02/prod/terraform.tfstate"
dynamodb_lock_table = "your-state-lock-table"
```

**Important**: S3 bucket names must be globally unique!

## 🚀 Deployment

### Local Deployment

#### Step 1: Initialize Terraform
```bash
cd terraform
terraform init
```

This will:
- Configure the S3 backend
- Download AWS provider plugins
- Initialize modules

#### Step 2: Validate Configuration
```bash
terraform validate
terraform fmt -check
```

#### Step 3: Plan Infrastructure Changes
```bash
terraform plan
```

Review the planned changes. You should see resources for:
- 1x S3 bucket (website)
- 2x DynamoDB tables (DeploymentTracking, ResumeAnalytics)
- 1x IAM role (for GitHub Actions)
- S3 bucket policies and configurations

#### Step 4: Apply Infrastructure
```bash
terraform apply
# Type 'yes' when prompted
```

**Expected outputs:**
```
bucket_name = "captains-bucket01312025"
website_url = "captains-bucket01312025.s3-website-us-east-1.amazonaws.com"
deployment_tracking_table_name = "DeploymentTracking"
resume_analytics_table_name = "ResumeAnalytics"
```

#### Step 5: Generate and Deploy Resume

```bash
python terraform/scripts/generate_and_deploy.py \
  --env prod \
  --bucket captains-bucket01312025 \
  --region us-east-1
```

**Script arguments:**
- `--env`: Environment (`prod`, `beta`, `dev`) - determines S3 path
- `--bucket`: S3 bucket name (required)
- `--region`: AWS region (optional, defaults to configured region)
- `--template`: Path to markdown resume (optional, default: `resume_template.md`)
- `--model-id`: Specific Bedrock model ID (optional, auto-selects if not provided)

**Example output:**
```
🚀 Starting resume generation and deployment
📝 Environment: prod
🪣 Bucket: captains-bucket01312025
✅ Loaded resume template (24074 chars)
🤖 Calling Amazon Bedrock to generate HTML...
🤖 Attempting foundation model id: us.anthropic.claude-3-5-sonnet-20241022-v2:0
✅ Successfully used foundation model: us.anthropic.claude-3-5-sonnet-20241022-v2:0
✅ Generated HTML (length: 15432 chars)
☁️ Uploading to S3...
📤 Uploading to s3://captains-bucket01312025/index.html
✅ Successfully uploaded to S3.
🌐 Resume URL: https://captains-bucket01312025.s3.us-east-1.amazonaws.com/index.html
🎉 Deployment complete!
```

### Automated Deployment (CI/CD)

#### Production Workflow (`deploy_prod.yml`)

**Trigger**: Push to `main` branch

**Steps:**
1. Checkout code
2. Set up Python 3.12
3. Install dependencies (pip, pytest, flake8, requirements.txt)
4. Configure AWS credentials
5. Install boto3
6. Set up Terraform 1.6.0
7. Run `generate_and_deploy.py` script
   - Generates AI resume from `resume_template.md`
   - Uploads to S3 bucket at `index.html`

**Environment variables:**
- `AWS_REGION`: From secrets
- `AWS_ACCESS_KEY_ID`: From secrets
- `AWS_SECRET_ACCESS_KEY`: From secrets
- `BUCKET_NAME`: From secrets (`RESUME_BUCKET`)
- `S3_PREFIX`: `prod`

#### Non-Production Workflow (`deploy_npe.yml`)

**Trigger**: Pull request to `main`, `dev`, or `beta` branches

**Steps:**
1. Checkout code
2. Set up Terraform 1.6.0
3. Run `terraform init -reconfigure`
4. Run `terraform plan -out=tfplan`
5. **If branch is `beta`**: Run `terraform apply tfplan`
6. **If branch is `beta`**: Run post-deploy Python script
   - Uploads to `beta/index.html`

**Workflow Logic:**
```yaml
- Terraform plan: Always runs on PR
- Terraform apply: Only on beta branch
- Post-deployment script: Only on beta branch
```

### Deployment Strategy

| Branch | Workflow | Terraform | Resume Generation | S3 Path |
|--------|----------|-----------|-------------------|---------|
| `main` | `deploy_prod.yml` | Not run | ✅ Yes | `index.html` |
| `beta` | `deploy_npe.yml` | ✅ Apply | ✅ Yes | `beta/index.html` |
| `dev` (PR) | `deploy_npe.yml` | Plan only | ❌ No | - |

## 📦 Terraform Modules

### 1. S3 Website Module (`modules/s3_website/`)

Creates an S3 bucket configured for static website hosting with public access.

**Resources Created:**
- `aws_s3_bucket` - Main bucket for hosting
- `aws_s3_bucket_versioning` - Version control for objects
- `aws_s3_bucket_website_configuration` - Website hosting settings
- `aws_s3_bucket_public_access_block` - Public access configuration
- `aws_s3_bucket_policy` - Public read policy

**Usage:**
```hcl
module "site_bucket" {
  source      = "./modules/s3_website"
  bucket_name = "my-unique-resume-bucket"
  public_read = true
}
```

**Inputs:**
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `bucket_name` | string | (required) | Globally unique S3 bucket name |
| `enable_versioning` | bool | `false` | Enable S3 versioning |
| `public_read` | bool | `false` | Allow public read access |

**Outputs:**
- `bucket_id` - S3 bucket ID
- `website_endpoint` - S3 website endpoint URL

**Configuration Details:**
```hcl
# Automatically configured:
index_document = "index.html"
error_document = "error.html"
versioning_status = "Enabled" or "Suspended"
```

### 2. DynamoDB Table Module (`modules/dynamodb_table/`)

Creates a DynamoDB table with configurable hash key and billing mode.

**Resources Created:**
- `aws_dynamodb_table` - DynamoDB table with hash key

**Usage:**
```hcl
module "deployment_tracking_table" {
  source        = "./modules/dynamodb_table"
  table_name    = "DeploymentTracking"
  hash_key_name = "CommitSHA"
}

module "resume_analytics_table" {
  source        = "./modules/dynamodb_table"
  table_name    = "ResumeAnalytics"
  hash_key_name = "ResumeID"
}
```

**Inputs:**
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `table_name` | string | (required) | DynamoDB table name |
| `hash_key_name` | string | (required) | Primary hash key attribute name |
| `billing_mode` | string | `"PAY_PER_REQUEST"` | Billing mode |

**Outputs:**
- `table_name` - DynamoDB table name
- `table_arn` - DynamoDB table ARN

### 3. IAM for GitHub Actions Module (`modules/iam_for_github_actions/`)

Creates IAM role with OIDC trust relationship for GitHub Actions authentication.

**Resources Created:**
- `aws_iam_role` - IAM role for GitHub Actions
- `aws_iam_role_policy` - Inline policy with S3 and Bedrock permissions
- Trust policy configured for GitHub OIDC provider

**Usage:**
```hcl
module "github_actions_iam" {
  source         = "./modules/iam_for_github_actions"
  role_name      = "github-actions-resume-role"
  environment    = "prod"
  s3_bucket      = "my-resume-bucket"
  aws_account_id = "123456789012"
  region         = "us-east-1"
  github_repo    = "my-org/my-repo"
}
```

**Inputs:**
| Variable | Type | Description |
|----------|------|-------------|
| `role_name` | string | IAM role name |
| `environment` | string | Environment (prod/beta/dev) |
| `s3_bucket` | string | S3 bucket for access permissions |
| `aws_account_id` | string | AWS account ID |
| `region` | string | AWS region |
| `github_repo` | string | GitHub repository (org/repo format) |

**Outputs:**
- `role_arn` - IAM role ARN
- `role_name` - IAM role name

**Permissions Granted:**
- S3: Full access to specified bucket
- Bedrock: Model invocation and inference profile listing
- Logs: CloudWatch Logs creation (optional)

## 🤖 How the AI Resume Generator Works

The `generate_and_deploy.py` script implements an intelligent resume generation system with robust error handling.

### Script Flow

```
1. Parse CLI Arguments
   ├── --env: prod/beta/dev
   ├── --bucket: S3 bucket name
   ├── --region: AWS region
   ├── --template: resume_template.md
   └── --model-id: (optional) specific model

2. Read Resume Template
   └── Load markdown from file system

3. Call AWS Bedrock API
   ├── Try Foundation Models (in order):
   │   ├── us.anthropic.claude-3-5-sonnet-20241022-v2:0
   │   ├── us.anthropic.claude-3-5-sonnet-20240620-v1:0
   │   ├── anthropic.claude-3-5-sonnet-20240620-v1:0
   │   ├── anthropic.claude-3-sonnet-20240229-v1:0
   │   ├── us.anthropic.claude-3-5-haiku-20241022-v1:0
   │   └── anthropic.claude-3-5-haiku-20241022-v1:0
   │
   ├── On Throughput Error:
   │   └── Auto-discover Inference Profile
   │       ├── List system-defined profiles
   │       ├── Match model prefix
   │       └── Retry with profile ID
   │
   └── Return Generated HTML

4. Upload to S3
   ├── Determine object key:
   │   ├── prod → index.html
   │   └── beta/dev → {env}/index.html
   ├── Set ContentType: text/html
   └── Put object to S3

5. Output Website URL
   └── https://{bucket}.s3.{region}.amazonaws.com/{key}
```

### AI Prompt Engineering

The script uses a carefully crafted prompt that instructs Claude to:
- Generate a **complete standalone HTML document**
- Apply **modern, professional design** with embedded CSS
- Ensure **mobile-responsive** layout
- Use **good typography** and whitespace
- Implement **ATS-friendly** structure
- Follow **proper heading hierarchy**
- No explanatory text - pure HTML output

### Error Handling

| Error Type | Handling Strategy |
|------------|-------------------|
| **Throughput Quota** | Auto-discover and use inference profile |
| **Model Not Available** | Try next model in priority list |
| **File Not Found** | Exit with clear error message |
| **AWS Credentials** | Boto3 default credential chain |
| **All Models Fail** | Display troubleshooting tips |

## 🔧 Development Workflow

### Recommended Branch Strategy

```
main (production)
  ├── beta (staging)
  │     └── feature/new-feature
  └── dev (development)
```

### Step-by-Step Workflow

#### 1. Create Feature Branch
```bash
git checkout beta
git pull origin beta
git checkout -b feature/add-analytics-tracking
```

#### 2. Make Changes
Edit Terraform files, Python scripts, or workflows as needed.

#### 3. Test Locally
```bash
# Terraform validation
cd terraform
terraform fmt
terraform validate
terraform plan

# Python linting
flake8 terraform/scripts/generate_and_deploy.py

# Pre-commit hooks (if installed)
pre-commit run --all-files
```

#### 4. Commit and Push
```bash
git add .
git commit -m "feat: add analytics tracking to deployment script"
git push origin feature/add-analytics-tracking
```

#### 5. Create Pull Request
- **Target**: `beta` branch
- **Auto-runs**: `deploy_npe.yml` workflow
  - Terraform plan
  - Validation checks
- **Review**: Check workflow results
- **Merge**: After approval

#### 6. Deploy to Beta
```bash
git checkout beta
git merge feature/add-analytics-tracking
git push origin beta
```

This triggers:
- Terraform apply (on beta branch)
- Resume generation to `beta/index.html`

#### 7. Promote to Production
```bash
git checkout main
git merge beta
git push origin main
```

This triggers:
- Resume generation to `index.html` (production)

## 🧪 Testing

### Pre-commit Hooks

If you have pre-commit hooks installed:

```bash
# Run all hooks
pre-commit run --all-files

# Run specific hooks
pre-commit run terraform-fmt --all-files
pre-commit run flake8 --all-files
pre-commit run markdownlint --all-files

# Auto-update hook versions
pre-commit autoupdate
```

### Terraform Testing

```bash
cd terraform

# Format all .tf files
terraform fmt -recursive

# Check formatting without changes
terraform fmt -check -recursive

# Validate configuration
terraform validate

# Plan without applying
terraform plan

# Plan with variable file
terraform plan -var-file="terraform.tfvars"
```

### Python Testing

```bash
# Lint with flake8
flake8 terraform/scripts/generate_and_deploy.py

# Check specific errors
flake8 --select=E,W terraform/scripts/

# Test script with dry-run (add --dry-run flag to script)
python terraform/scripts/generate_and_deploy.py \
  --env dev \
  --bucket test-bucket \
  --template resume_template.md
```

### Integration Testing

Test the complete workflow locally:

```bash
# 1. Deploy infrastructure
cd terraform
terraform apply -auto-approve

# 2. Generate and deploy resume
python scripts/generate_and_deploy.py \
  --env dev \
  --bucket $(terraform output -raw bucket_name) \
  --region us-east-1

# 3. Verify deployment
WEBSITE_URL=$(terraform output -raw website_url)
curl -I "https://$WEBSITE_URL/dev/index.html"
```

## 🔒 Security Considerations

### Infrastructure Security

| Layer | Security Measure | Implementation |
|-------|------------------|----------------|
| **State Management** | Encrypted at rest | S3 bucket encryption enabled |
| **State Locking** | Prevents concurrent modifications | DynamoDB table (`dyning_table`) |
| **IAM Roles** | Least privilege access | Scoped policies for S3, Bedrock only |
| **S3 Bucket** | Public read for website only | Explicit public access block config |
| **Secrets** | GitHub encrypted secrets | AWS credentials stored securely |
| **OIDC** | Temporary credentials | IAM role assumption (recommended over static keys) |

### Best Practices

1. **Never Commit Secrets**
   ```bash
   # Add to .gitignore:
   *.tfvars
   *.env
   .env.local
   terraform.tfstate
   terraform.tfstate.backup
   ```

2. **Use IAM Roles Over Access Keys**
   - Prefer OIDC for GitHub Actions
   - Rotate access keys regularly if used
   - Use AWS STS temporary credentials

3. **Enable MFA for AWS Console**
   - Protect against credential compromise
   - Required for production AWS accounts

4. **Audit S3 Bucket Policies**
   ```bash
   aws s3api get-bucket-policy --bucket your-bucket-name
   ```

5. **Monitor with CloudTrail**
   - Enable CloudTrail for all API calls
   - Review Bedrock invocations and costs

### Security Checklist

- [ ] AWS credentials stored in GitHub secrets (not code)
- [ ] S3 state bucket has encryption enabled
- [ ] DynamoDB state lock table exists
- [ ] IAM roles follow least privilege
- [ ] No hardcoded credentials in code
- [ ] Pre-commit hooks enabled for secret scanning
- [ ] MFA enabled on AWS root account
- [ ] Regular security audits scheduled

## 🐛 Troubleshooting

### AWS Bedrock Issues

#### Issue: "Model not found" or "Access Denied"

**Cause**: Bedrock model access not enabled in your AWS account

**Solution**:
```bash
# 1. Go to AWS Bedrock Console
# 2. Navigate to "Model access"
# 3. Request access to Claude models
# 4. Wait for approval (usually instant)

# Verify access via CLI:
aws bedrock list-foundation-models --region us-east-1
```

#### Issue: "ThrottlingException" or "On-demand throughput quota exceeded"

**Cause**: Bedrock on-demand quota limits reached

**Solution**: The script automatically handles this by discovering inference profiles. If it still fails:
```bash
# Request quota increase:
# AWS Console > Service Quotas > AWS Bedrock > Request quota increase

# Or use a specific inference profile:
python terraform/scripts/generate_and_deploy.py \
  --env prod \
  --bucket your-bucket \
  --model-id "arn:aws:bedrock:us-east-1::inference-profile/us.anthropic.claude-3-5-sonnet-v2:0"
```

### Terraform Issues

#### Issue: "Error: Backend initialization failed"

**Cause**: S3 bucket or DynamoDB table doesn't exist

**Solution**:
```bash
# Create state bucket
aws s3 mb s3://your-terraform-state-bucket --region us-east-1
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Create state lock table
aws dynamodb create-table \
  --table-name your-state-lock-table \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

#### Issue: "Error: state is locked"

**Cause**: Previous Terraform operation didn't complete cleanly

**Solution**:
```bash
# View lock info
terraform force-unlock <LOCK_ID>

# If that fails, manually delete from DynamoDB:
aws dynamodb delete-item \
  --table-name your-state-lock-table \
  --key '{"LockID":{"S":"your-state-bucket/path/to/state"}}'
```

#### Issue: "S3 bucket name already exists"

**Cause**: S3 bucket names are globally unique

**Solution**:
```hcl
# Update terraform/variables.tf:
variable "bucket_name" {
  default = "your-unique-name-${random_id.suffix.hex}"
}

# Or use a different naming pattern:
bucket_name = "resume-yourname-20250101"
```

### GitHub Actions Issues

#### Issue: Workflow fails with "AWS credentials not configured"

**Cause**: GitHub secrets not set

**Solution**:
```bash
# Verify secrets are set:
# Repository Settings > Secrets > Actions

# Required secrets:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - AWS_REGION
# - RESUME_BUCKET
```

#### Issue: "terraform: command not found"

**Cause**: Terraform setup step failed

**Solution**: Check workflow uses correct action version:
```yaml
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: "1.6.0"
```

#### Issue: Python dependencies installation fails

**Cause**: requirements.txt not found or incompatible versions

**Solution**:
```yaml
# Ensure requirements.txt exists in repo root
# Install with specific Python version:
- name: Set up Python 3.12
  uses: actions/setup-python@v3
  with:
    python-version: "3.12"

- name: Install dependencies
  run: |
    pip install --upgrade pip
    pip install -r requirements.txt
```

### S3 Website Issues

#### Issue: "403 Forbidden" when accessing website

**Cause**: Bucket policy doesn't allow public read

**Solution**:
```bash
# Verify bucket policy:
aws s3api get-bucket-policy --bucket your-bucket-name

# Check public access block:
aws s3api get-public-access-block --bucket your-bucket-name

# Re-apply Terraform to fix:
cd terraform
terraform apply -target=module.site_bucket
```

#### Issue: Website shows "NoSuchKey" error

**Cause**: index.html not uploaded or wrong S3 path

**Solution**:
```bash
# List bucket contents:
aws s3 ls s3://your-bucket-name/

# Manually upload for testing:
aws s3 cp resume.html s3://your-bucket-name/index.html \
  --content-type text/html \
  --acl public-read
```

### Python Script Issues

#### Issue: "FileNotFoundError: resume_template.md"

**Cause**: Script can't find template file

**Solution**:
```bash
# Run from project root:
cd /path/to/redLUIT_Nov2025_AWSBedRockProject02

# Or specify absolute path:
python terraform/scripts/generate_and_deploy.py \
  --template /full/path/to/resume_template.md \
  --env prod \
  --bucket your-bucket
```

#### Issue: "ModuleNotFoundError: No module named 'boto3'"

**Cause**: Python dependencies not installed

**Solution**:
```bash
pip install -r requirements.txt

# Or install individually:
pip install boto3>=1.26.0 botocore urllib3>=1.26.16 markdown2
```

### Debugging Tips

#### Enable Terraform Debug Logging
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform plan
```

#### Enable AWS CLI Debug
```bash
aws bedrock invoke-model \
  --model-id anthropic.claude-3-5-sonnet-20240620-v1:0 \
  --body '{"prompt":"test"}' \
  --debug \
  output.json
```

#### Test Bedrock Access
```python
import boto3

bedrock = boto3.client('bedrock', region_name='us-east-1')
models = bedrock.list_foundation_models()
print([m['modelId'] for m in models['modelSummaries']])
```

## 📊 Project Status

Current implementation status:

| Feature | Status | Notes |
|---------|--------|-------|
| **Infrastructure Provisioning** | ✅ Complete | Terraform modules for S3, DynamoDB, IAM |
| **CI/CD Pipeline** | ✅ Complete | Dual workflows for prod and NPE |
| **AI Resume Generation** | ✅ Complete | Multi-model support with fallback |
| **S3 Website Hosting** | ✅ Complete | Public static website configuration |
| **DynamoDB Tracking** | ✅ Complete | Tables for deployments and analytics |
| **Pre-commit Hooks** | ✅ Complete | Terraform, Python, Markdown linting |
| **Multi-Environment** | ✅ Complete | Support for prod, beta, dev |
| **Error Handling** | ✅ Complete | Robust fallback and troubleshooting |
| **CloudFront CDN** | ✅ Complete | HTTPS with OAC for secure S3 access |
| **Custom Domain** | ✅ Complete | ACM certificates + DNS configuration |
| **CloudWatch Monitoring** | 🚧 Future | Metrics and alarms |
| **Cost Optimization** | 🚧 Future | S3 lifecycle policies, reserved capacity |

## 📖 Additional Documentation

This repository includes comprehensive guides for various deployment scenarios:

### CloudFront & Custom Domain Setup
- **[CUSTOM_DOMAIN_SETUP.md](CUSTOM_DOMAIN_SETUP.md)** - Complete guide for setting up custom domain (www.jenom.com) with CloudFront, including ACM certificate setup, DNS configuration, and troubleshooting
- **[DEPLOY_JENOM_COM.md](DEPLOY_JENOM_COM.md)** - Quick start deployment guide with step-by-step instructions for www.jenom.com
- **[DNS_CONFIGURATION_JENOM.md](DNS_CONFIGURATION_JENOM.md)** - DNS provider-specific instructions (GoDaddy, Namecheap, Route53, Cloudflare, etc.)

### CloudFront Integration
- **[CLOUDFRONT_ONLY_ACCESS.md](CLOUDFRONT_ONLY_ACCESS.md)** - Documentation for CloudFront-only access model, security benefits, and migration from public S3
- **[CLOUDFRONT_SETUP.md](CLOUDFRONT_SETUP.md)** - CloudFront module documentation and configuration options
- **[CLOUDFRONT_SUMMARY.md](CLOUDFRONT_SUMMARY.md)** - Quick reference for CloudFront features and benefits

### Infrastructure Documentation
- **[terraform/README.md](terraform/README.md)** - Quick reference for Terraform deployment and module usage
- **[terraform/modules/s3_website/README.md](terraform/modules/s3_website/README.md)** - S3 website module documentation
- **[terraform/modules/cloudfront/README.md](terraform/modules/cloudfront/README.md)** - CloudFront module documentation

### Security Model

The infrastructure enforces **CloudFront-only access** with the following security layers:

```
┌─────────────────────────────────────────┐
│         Access Control Matrix            │
├─────────────────────────────────────────┤
│ Direct S3 HTTP Access:      ❌ BLOCKED  │
│ Direct S3 HTTPS Access:     ❌ BLOCKED  │
│ Public Bucket Policy:       ❌ REMOVED  │
│ Public ACLs:                ❌ BLOCKED  │
│ CloudFront OAC Access:      ✅ ALLOWED  │
└─────────────────────────────────────────┘
```

**Benefits:**
- ✅ HTTPS-only access (TLS 1.2+)
- ✅ Global CDN with 400+ edge locations
- ✅ ~90% cost reduction vs direct S3
- ✅ Compliance ready (PCI DSS, HIPAA, SOC 2, GDPR)
- ✅ DDoS protection with AWS Shield Standard
- ✅ Optional WAF integration

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Educational Purpose**: Part of the Level Up In Tech (LUIT) November 2025 Cohort program.

## 👥 Author

**Shehu J**
- **GitHub**: [@shehuj](https://github.com/shehuj)
- **Project**: LUIT November 2025 Cohort - AWS Bedrock Project 02
- **Program**: Level Up In Tech

## 🙏 Acknowledgments

- **Level Up In Tech (LUIT)** - For providing structured cloud engineering training
- **AWS Bedrock Team** - For making Claude AI models accessible via API
- **Anthropic** - For developing Claude AI models
- **HashiCorp** - For Terraform and infrastructure as code tools
- **GitHub** - For Actions CI/CD platform
- **Open Source Community** - For tools and libraries used in this project

## 📚 Resources

### Official Documentation
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [AWS Bedrock Model IDs](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Boto3 Documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)

### Learning Resources
- [Level Up In Tech](https://www.levelupintech.com/)
- [Terraform Learn](https://learn.hashicorp.com/terraform)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### Community
- [Terraform AWS Modules](https://github.com/terraform-aws-modules)
- [Awesome Terraform](https://github.com/shuaibiyy/awesome-terraform)
- [AWS Samples](https://github.com/aws-samples)

## 🤝 Contributing

Contributions are welcome! This is an educational project, and feedback helps improve it.

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Contribution Guidelines

- Follow existing code style and conventions
- Add tests for new features
- Update documentation for changes
- Run pre-commit hooks before committing
- Ensure all workflows pass

## 📞 Support

If you encounter issues:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Review [GitHub Issues](https://github.com/shehuj/redLUIT_Nov2025_AWSBedRockProject02/issues)
3. Open a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Terraform version, etc.)

---

<div align="center">

**Built with ❤️ for the LUIT November 2025 Cohort**

⭐ Star this repo if you found it helpful! ⭐

</div>