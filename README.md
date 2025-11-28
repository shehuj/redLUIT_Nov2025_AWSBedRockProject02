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

## 📋 Features

- **AI-Powered Resume Generation**: Leverages AWS Bedrock foundation models to generate customized resumes
- **Automated Deployment**: GitHub Actions workflow for continuous integration and deployment
- **Infrastructure as Code**: Modular Terraform configuration for reproducible infrastructure
- **Static Website Hosting**: S3-based resume hosting with CloudFront support
- **Security Best Practices**: 
  - IAM roles with least privilege access
  - OIDC authentication for GitHub Actions
  - Encrypted state management with DynamoDB locking
- **Code Quality**: Pre-commit hooks for linting and formatting (Terraform, Python, Markdown)

## 🛠️ Technology Stack

### Infrastructure
- **AWS Services**: S3, DynamoDB, IAM, Bedrock
- **IaC**: Terraform (modular architecture)
- **CI/CD**: GitHub Actions

### Application
- **Language**: Python 3.x
- **AI/ML**: AWS Bedrock SDK
- **AWS SDK**: Boto3

### Development Tools
- **Pre-commit**: Automated code quality checks
- **Linters**: 
  - Terraform: `terraform fmt`, `terraform validate`
  - Python: `black`, `flake8`
  - Markdown: `markdownlint-cli2`

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/
│       └── resume-ci-cd.yml          # CI/CD pipeline configuration
├── terraform/
│   ├── backend.tf                    # Terraform backend configuration
│   ├── main.tf                       # Root module
│   ├── variables.tf                  # Input variables
│   ├── outputs.tf                    # Output values
│   └── modules/
│       ├── dynamodb_table/           # DynamoDB table module
│       ├── iam_for_github_actions/   # IAM OIDC authentication module
│       └── s3_website/               # S3 static website hosting module
├── scripts/
│   └── generate_and_deploy.py        # Resume generation and deployment script
├── .pre-commit-config.yaml           # Pre-commit hooks configuration
├── .markdownlint-cli2.yaml           # Markdown linting rules
└── README.md                         # This file
```

## 🚦 Getting Started

### Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.6.0
- Python >= 3.9
- GitHub account
- AWS CLI configured locally

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/shehuj/redLUIT_Nov2025_AWSBedRockProject02.git
   cd redLUIT_Nov2025_AWSBedRockProject02
   ```

2. **Install Python dependencies**
   ```bash
   pip install boto3 requests
   # Add any additional AI SDK requirements
   ```

3. **Install pre-commit hooks**
   ```bash
   pip install pre-commit
   pre-commit install
   ```

4. **Configure AWS credentials**
   ```bash
   aws configure
   ```

### Configuration

1. **Set up GitHub Secrets**
   
   Navigate to your repository settings and add these secrets:
   - `AWS_REGION`: Your AWS region (e.g., `us-east-1`)
   - `RESUME_BUCKET`: S3 bucket name for hosting
   - `AWS_ACCESS_KEY_ID`: AWS access key (or use OIDC)
   - `AWS_SECRET_ACCESS_KEY`: AWS secret key (or use OIDC)

2. **Configure Terraform Backend**
   
   Update `terraform/backend.tf` with your S3 bucket and DynamoDB table:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-terraform-state-bucket"
       key            = "resume/terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "terraform-state-lock"
       encrypt        = true
     }
   }
   ```

3. **Update Terraform Variables**
   
   Create a `terraform.tfvars` file:
   ```hcl
   aws_region      = "us-east-1"
   bucket_name     = "your-resume-bucket"
   github_org      = "your-github-org"
   github_repo     = "your-repo-name"
   ```

## 🚀 Deployment

### Local Deployment

1. **Initialize Terraform**
   ```bash
   cd terraform
   terraform init
   ```

2. **Plan infrastructure changes**
   ```bash
   terraform plan
   ```

3. **Apply infrastructure**
   ```bash
   terraform apply
   ```

4. **Generate and deploy resume**
   ```bash
   python scripts/generate_and_deploy.py --env prod --bucket your-resume-bucket
   ```

### Automated Deployment (CI/CD)

The GitHub Actions workflow automatically:
1. Runs pre-commit hooks on all files
2. Validates and formats Terraform code
3. Plans infrastructure changes
4. Applies changes on push to `main` branch
5. Generates and deploys the resume

**Workflow triggers:**
- **Pull Request**: Validation and plan only (to `main`, `feature/*`, `beta`)
- **Push to main**: Full deployment (validation, plan, apply, deploy)

## 📦 Terraform Modules

### DynamoDB Table Module
Creates a DynamoDB table for Terraform state locking.

**Usage:**
```hcl
module "state_lock_table" {
  source = "./modules/dynamodb_table"
  
  table_name   = "terraform-state-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"
}
```

### IAM for GitHub Actions Module
Sets up OIDC authentication for GitHub Actions to assume AWS roles.

**Usage:**
```hcl
module "github_actions_role" {
  source = "./modules/iam_for_github_actions"
  
  github_org  = "your-org"
  github_repo = "your-repo"
  role_name   = "github-actions-deploy-role"
  
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}
```

### S3 Website Module
Creates and configures an S3 bucket for static website hosting.

**Usage:**
```hcl
module "resume_website" {
  source = "./modules/s3_website"
  
  bucket_name = "my-resume-site"
  index_document = "index.html"
  error_document = "error.html"
}
```

## 🔧 Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes and test locally**
   ```bash
   # Run pre-commit checks
   pre-commit run --all-files
   
   # Test Terraform changes
   terraform fmt -recursive
   terraform validate
   terraform plan
   ```

3. **Commit and push**
   ```bash
   git add .
   git commit -m "Description of changes"
   git push origin feature/your-feature-name
   ```

4. **Create Pull Request**
   - GitHub Actions will run validation checks
   - Review the Terraform plan in PR comments
   - Merge when approved

## 🧪 Testing

### Pre-commit Hooks
```bash
# Run all hooks
pre-commit run --all-files

# Run specific hook
pre-commit run terraform-fmt --all-files
```

### Terraform Testing
```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform validate

# Plan (dry-run)
terraform plan
```

### Python Testing
```bash
# Format with black
black scripts/

# Lint with flake8
flake8 scripts/
```

## 🔒 Security Considerations

- **State Management**: Terraform state is stored in encrypted S3 with DynamoDB locking
- **Access Control**: IAM roles follow least privilege principle
- **Secrets**: Never commit AWS credentials or sensitive data
- **OIDC**: Use OpenID Connect instead of long-lived credentials where possible
- **Scanning**: Pre-commit hooks check for accidentally committed secrets

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and pre-commit hooks
5. Submit a pull request

## 📝 License

This project is part of the Level Up In Tech program and is for educational purposes.

## 👥 Author

**Shehu J**
- GitHub: [@shehuj](https://github.com/shehuj)
- Project: LUIT November 2025 Cohort - AWS Bedrock Project 02

## 🙏 Acknowledgments

- Level Up In Tech (LUIT) program
- AWS Bedrock team for AI capabilities
- Terraform community for IaC modules
- GitHub Actions for CI/CD automation

## 📚 Resources

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [LUIT Program](https://www.levelupintech.com/)

## 🐛 Troubleshooting

### Common Issues

**Issue: Terraform state locked**
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

**Issue: AWS credentials error**
```bash
# Verify credentials
aws sts get-caller-identity
```

**Issue: Pre-commit hooks failing**
```bash
# Update hooks
pre-commit autoupdate

# Clear cache
pre-commit clean
```

**Issue: GitHub Actions failing**
- Check repository secrets are configured
- Verify IAM permissions
- Review workflow logs in Actions tab

## 📊 Project Status

- ✅ Infrastructure provisioning with Terraform
- ✅ CI/CD pipeline with GitHub Actions
- ✅ Pre-commit hooks for code quality
- ✅ Resume generation with AWS Bedrock
- ✅ S3 static website hosting
- 🚧 CloudFront distribution (optional enhancement)
- 🚧 Custom domain integration (optional enhancement)

---

**Built with ❤️ for the LUIT November 2025 Cohort**