# Data Source for Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Compute Instance
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  # User Data Script to configure Web Server
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl enable --now nginx
              echo "<h1>Cloud Infrastructure Deployed via Terraform - Session 19</h1>" > /usr/share/nginx/html/index.html
              echo "<p>Connected S3 Bucket: ${aws_s3_bucket.storage.id}</p>" >> /usr/share/nginx/html/index.html
              EOF

  # Explicit dependency demonstration
  depends_on = [
    aws_internet_gateway.gw,
    aws_s3_bucket.storage
  ]

  tags = {
    Name = "session19-web-server"
    Role = "WebServer"
  }
}
