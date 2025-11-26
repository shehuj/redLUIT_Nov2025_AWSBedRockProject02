terraform {
  backend "s3" {
    bucket         = "ec2-shutdown-lambda-bucket"   # <--- specify actual bucket name here
    key            = "milestone02-resume-website/terraform.tfstate"
    region         = "us-east-1"                # <--- specify actual region here
    encrypt        = true
    dynamodb_table = "dyning_table"  # optional, for state locking
  }
}