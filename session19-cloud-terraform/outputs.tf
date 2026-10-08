output "vpc_id" {
  description = "ID of the provisioned custom VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web_sg.id
}

output "s3_bucket_name" {
  description = "Name of the provisioned S3 bucket"
  value       = aws_s3_bucket.storage.id
}

output "s3_bucket_arn" {
  description = "ARN of the provisioned S3 bucket"
  value       = aws_s3_bucket.storage.arn
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 web server"
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "HTTP access URL for the deployed web server"
  value       = "http://${aws_instance.web.public_ip}"
}
