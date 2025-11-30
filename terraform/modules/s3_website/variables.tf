variable "bucket_name" {
  description = "Name of the S3 bucket (CloudFront OAC access only)"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to S3 bucket resources"
  type        = map(string)
  default     = {}
}
