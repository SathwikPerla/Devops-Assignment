variable "aws_region" {
  type        = string
  description = "AWS region for provisioning resources"
  default     = "ap-south-1"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique name for the S3 bucket"
  default     = "sathwik-devops-s3-demo-bucket-2026"
}

variable "environment" {
  type        = string
  description = "Target deployment environment"
  default     = "development"
}
