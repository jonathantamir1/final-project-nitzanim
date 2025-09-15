# Status Page Application - Main Terraform Configuration
# This file defines the main infrastructure components

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "status-page"
      Environment = var.environment
      ManagedBy   = "terraform"
      AAJ         = "AAJ"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Local values
locals {
  name = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    AAJ         = "AAJ"
  }
}

# VPC Module
module "networking" {
  source = "./modules/networking"
  
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  
  availability_zones = data.aws_availability_zones.available.names
  vpc_cidr          = var.vpc_cidr
  
  tags = local.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnet_ids
  public_subnets  = module.networking.public_subnet_ids
  
  node_groups = var.eks_node_groups
  
  tags = local.common_tags
}

# RDS Module
module "rds" {
  source = "./modules/rds"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnet_ids
  
  db_instance_class    = var.rds_instance_class
  db_allocated_storage = var.rds_allocated_storage
  db_engine_version   = var.rds_engine_version
  
  tags = local.common_tags
}

# Redis Module
module "redis" {
  source = "./modules/redis"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnet_ids
  
  node_type = var.redis_node_type
  
  tags = local.common_tags
}

# Jenkins Module
module "jenkins" {
  source = "./modules/jenkins"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id          = module.networking.vpc_id
  public_subnets  = module.networking.public_subnet_ids
  
  instance_type = var.jenkins_instance_type
  key_pair_name = var.key_pair_name
  
  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id = module.networking.vpc_id
  
  tags = local.common_tags
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = module.redis.endpoint
  sensitive   = true
}

output "jenkins_public_ip" {
  description = "Public IP of Jenkins server"
  value       = module.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${module.jenkins.public_ip}:8080"
}
