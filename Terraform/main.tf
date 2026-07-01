terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# -------------------------
# VPC
# -------------------------

resource "aws_vpc" "notesapp" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "notesapp-vpc"
  }
}

# -------------------------
# SUBNET
# -------------------------

resource "aws_subnet" "notesapp" {
  vpc_id                  = aws_vpc.notesapp.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "notesapp-subnet"
  }
}

# -------------------------
# INTERNET GATEWAY
# -------------------------

resource "aws_internet_gateway" "notesapp" {
  vpc_id = aws_vpc.notesapp.id

  tags = {
    Name = "notesapp-igw"
  }
}

# -------------------------
# ROUTE TABLE
# -------------------------

resource "aws_route_table" "notesapp" {
  vpc_id = aws_vpc.notesapp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.notesapp.id
  }

  tags = {
    Name = "notesapp-rt"
  }
}

resource "aws_route_table_association" "notesapp" {
  subnet_id      = aws_subnet.notesapp.id
  route_table_id = aws_route_table.notesapp.id
}

# -------------------------
# KEY PAIR
# -------------------------

resource "tls_private_key" "notesapp" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "notesapp" {
  key_name   = var.key_name
  public_key = tls_private_key.notesapp.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.notesapp.private_key_pem
  filename        = "${var.key_name}.pem"
  file_permission = "0400"
}

# -------------------------
# SECURITY GROUP
# -------------------------

resource "aws_security_group" "notesapp" {
  name        = "notesapp-sg"
  description = "NotesApp security group"
  vpc_id      = aws_vpc.notesapp.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NotesApp"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "notesapp-sg"
  }
}

# -------------------------
# AMI LOOKUP
# -------------------------

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -------------------------
# USER DATA
# -------------------------

locals {
  user_data = <<-EOF
    #!/bin/bash
    # Ansible connects over SSH - no bootstrap needed.
    # AL2023 ships with Python3, so Ansible works out of the box.
    echo "Instance ready for Ansible provisioning." >> /var/log/init.log
  EOF
}

# -------------------------
# EC2 INSTANCE
# -------------------------

resource "aws_instance" "notesapp" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.notesapp.key_name
  subnet_id              = aws_subnet.notesapp.id
  vpc_security_group_ids = [aws_security_group.notesapp.id]

  user_data = base64encode(local.user_data)

  tags = {
    Name = "notesapp-server"
  }
}
