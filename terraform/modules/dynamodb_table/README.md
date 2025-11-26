.
├── terraform/          ← root Terraform module  
│     ├── backend.tf      ← remote state config  
│     ├── environments/   ← environment-specific configs (beta, prod)  
│     │     ├── beta.tfvars  
│     │     └── prod.tfvars  
│     ├── main.tf       ← calls lower-level modules  
│     ├── variables.tf  
│     ├── outputs.tf  
│     └── README.md  
├── modules/                     ← reusable Terraform modules  
│     ├── s3_website/            ← module for S3 website bucket  
│     │     ├── main.tf  
│     │     ├── variables.tf  
│     │     ├── outputs.tf  
│     │     └── README.md  
│     ├── dynamodb_table/        ← module for a DynamoDB table  
│     │     ├── main.tf  
│     │     ├── variables.tf  
│     │     ├── outputs.tf  
│     │     └── README.md  
│     └── iam_for_github_actions/ ← module for IAM role + policy for GitHub Actions  
│           ├── main.tf  
│           ├── variables.tf  
│           ├── outputs.tf  
│           └── README.md  
├── scripts/  
│     └── generate_and_deploy.py  ← Python script (AI + deploy logic)  
├── resume_template.md  
├── .github/  
│     └── workflows/  
│           └── ci_cd.yml   ← GitHub Actions CI/CD workflow  
└── README.md