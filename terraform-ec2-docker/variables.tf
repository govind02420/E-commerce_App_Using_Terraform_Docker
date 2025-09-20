variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "instance_type" {
  type    = string
  default = "c7i-flex.large"
}

variable "ssh_key_name" {
  description = "Existing EC2 Key pair name"
  type        = string
}

variable "dockerhub_username" {
  description = "Docker Hub username"
  type        = string
  default     = "govind02420"
}

variable "mongo_data_dir" {
  description = "Host path to persist MongoDB data"
  type        = string
  default     = "/home/ubuntu/mongo-data"
}

variable "dockerhub_password" {
  description = "Docker Hub password (sensitive). Provide via terraform.tfvars, do NOT hard-code."
  type        = string
  sensitive   = true
}

variable "docker_images" {
  description = "Map of service -> image:tag"
  type        = map(string)
  default = {
    "user-service"    = "govind02420/user-service:1.0.0"
    "product-service" = "govind02420/product-service:1.0.0"
    "cart-service"    = "govind02420/cart-service:1.0.0"
    "order-service"   = "govind02420/order-service:1.0.0"
    "frontend"        = "govind02420/frontend:1.0.0"
  }
}
