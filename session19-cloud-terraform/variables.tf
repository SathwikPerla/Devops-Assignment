variable "aws_region" {
  description = "Target AWS Region for cloud infrastructure"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Target deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the custom VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnet placement"
  type        = string
  default     = "ap-south-1a"
}

variable "instance_type" {
  description = "EC2 compute instance type"
  type        = string
  default     = "t3.micro"
}

variable "s3_bucket_name" {
  description = "Globally unique name for the S3 bucket"
  type        = string
  default     = "sathwik-session19-cloud-terraform-demo-2026"
}
