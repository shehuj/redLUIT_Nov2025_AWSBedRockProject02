terraform {
  backend "s3" {
    bucket         = "ec2-shutdown-lambda-bucket"   # Using the bucket name from variables.tf
    key            = "bedrock-project02/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "dyning_table"  # More descriptive name for state locking
  }
}