variable "bucket_name" {
  description = "Name of S3 bucket for website hosting"
  type        = string
  default = "captains-bucket01312025"
}

variable "enable_versioning" {
  description = "Enable versioning on bucket"
  type        = bool
  default     = true
}

variable "public_read" {
  description = "Whether bucket objects should be publicly readable"
  type        = bool
  default     = true
}

variable "website_index_document" {
  description = "Index document for the website"
  type        = string
  default     = "index.html"
}

variable "website_error_document" {
  description = "Error document for the website"
  type        = string
  default     = "error.html"
}

variable "region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "us-east-1"
}