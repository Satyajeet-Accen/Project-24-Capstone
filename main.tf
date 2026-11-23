terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "satyajeet_chaos_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "satyajeet-chaos-vpc"
  }
}

resource "aws_internet_gateway" "satyajeet_chaos_igw" {
  vpc_id = aws_vpc.satyajeet_chaos_vpc.id
}

resource "aws_subnet" "satyajeet_chaos_subnet" {
  vpc_id                  = aws_vpc.satyajeet_chaos_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "satyajeet_chaos_rt" {
  vpc_id = aws_vpc.satyajeet_chaos_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.satyajeet_chaos_igw.id
  }
}

resource "aws_route_table_association" "satyajeet_chaos_rta" {
  subnet_id      = aws_subnet.satyajeet_chaos_subnet.id
  route_table_id = aws_route_table.satyajeet_chaos_rt.id
}

resource "aws_security_group" "satyajeet_chaos_sg" {
  name   = "satyajeet_chaos_sg"
  vpc_id = aws_vpc.satyajeet_chaos_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "satyajeet_chaos_instance" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.satyajeet_chaos_subnet.id
  vpc_security_group_ids = [aws_security_group.satyajeet_chaos_sg.id]

  user_data = <<-EOF
  #!/bin/bash
  dnf install -y httpd
  systemctl start httpd
  systemctl enable httpd
  echo "<h1>Satyajeet Chaos Testing App</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "satyajeet-chaos-instance"
  }
}
