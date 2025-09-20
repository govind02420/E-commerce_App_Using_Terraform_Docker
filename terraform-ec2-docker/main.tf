terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.14.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = { Name = "tf-ecomm-vpc" }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  tags = { Name = "tf-ecomm-public-subnet" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "tf-ecomm-igw" }
}

# Route Table + default route
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "tf-ecomm-public-rt" }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
resource "aws_security_group" "instance_sg" {
  name        = "tf-ecomm-sg"
  description = "Allow SSH, HTTP (frontend) and microservice ports"
  vpc_id      = aws_vpc.main.id

  # SSH from anywhere (you can restrict to your IP in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP frontend
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Frontend & microservices ports (public access)
  ingress {
    from_port   = 3000
    to_port     = 3004
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-ecomm-sg"
  }
}


# Ubuntu 22.04 AMI (Jammy)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 instance (single)
resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/userdata.tpl", {
    dockerhub_username    = var.dockerhub_username
    dockerhub_password    = var.dockerhub_password
    frontend_image        = var.docker_images["frontend"]
    user_service_image    = var.docker_images["user-service"]
    product_service_image = var.docker_images["product-service"]
    cart_service_image    = var.docker_images["cart-service"]
    order_service_image   = var.docker_images["order-service"]
    MONGO_DATA_DIR        = var.mongo_data_dir
  })

  tags = { Name = "tf-ecomm-app" }
}
