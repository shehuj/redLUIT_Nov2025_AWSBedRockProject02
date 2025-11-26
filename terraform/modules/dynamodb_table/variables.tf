variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "hash_key_name" {
  description = "Name of the hash (partition) key"
  type        = string
}

variable "hash_key_type" {
  description = "Type of the hash key (S, N, etc.)"
  type        = string
  default     = "S"
}

variable "billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "region" {
  description = "AWS region for the DynamoDB table"
  type        = string
  default     = "us-east-1"

}