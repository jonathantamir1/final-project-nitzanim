# Status Page Application - Variables
# This file defines all input variables for the Terraform configuration

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "status-page"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair"
  type        = string
  default     = "status-page-key"
}

# EKS Variables
variable "eks_node_groups" {
  description = "EKS node group configurations"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    min_size      = number
    max_size      = number
    desired_size  = number
    disk_size     = number
  }))
  default = {
    system = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      min_size      = 1
      max_size      = 3
      desired_size  = 2
      disk_size     = 50
    }
    application = {
      instance_types = ["t3.medium", "t3.large"]
      capacity_type  = "SPOT"
      min_size      = 1
      max_size      = 5
      desired_size  = 2
      disk_size     = 50
    }
  }
}

# RDS Variables
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"  # Cost optimization: using smallest instance
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20  # Cost optimization: minimal storage
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "14.9"
}

# Redis Variables
variable "redis_node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.t3.micro"  # Cost optimization: smallest instance
}

# Jenkins Variables
variable "jenkins_instance_type" {
  description = "Jenkins EC2 instance type"
  type        = string
  default     = "t3.small"  # Cost optimization: smaller instance
}

# Cost Optimization Variables
variable "enable_spot_instances" {
  description = "Enable spot instances for cost optimization"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for cost optimization"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7  # Cost optimization: minimal retention
}

# Monitoring Variables
variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring (costs more)"
  type        = bool
  default     = false  # Cost optimization: basic monitoring
}

# Security Variables
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # WARNING: Change this in production
}

variable "enable_waf" {
  description = "Enable AWS WAF"
  type        = bool
  default     = false  # Cost optimization: disable WAF initially
}
