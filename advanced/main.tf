terraform {
  required_version = ">= 1.13.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# ---------------------------------------------------------------------------
# Retrieve latest Amazon Linux 2023 AMI from SSM
# ---------------------------------------------------------------------------
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

# ---------------------------------------------------------------------------
# Discover the FIRST PUBLIC subnet automatically
# ---------------------------------------------------------------------------
# Get the default VPC
data "aws_vpc" "default" {
  default = false
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  subnet_id = data.aws_subnets.all.ids[0]
}


# ---------------------------------------------------------------------------
# IAM Role for SSM
# ---------------------------------------------------------------------------
resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# ---------------------------------------------------------------------------
# Security Group: no inbound, allow all outbound
# ---------------------------------------------------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "no-inbound-sg"
  description = "Security group with no inbound, all outbound"
  vpc_id      = data.aws_vpc.default.id

  # No inbound rules intentionally

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------
# EC2 Instance with public IP + SSM
# ---------------------------------------------------------------------------
resource "aws_instance" "secure_ec2" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = "t3.micro"
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name

  # PUBLIC IP ENABLED
  associate_public_ip_address = true

  # Enforce IMDSv2
  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "LabEC2REDO"
  }
}
