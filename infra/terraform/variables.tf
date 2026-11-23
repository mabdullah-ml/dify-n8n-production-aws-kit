variable "aws_region" {
  description = "Primary AWS region (Tokyo default)"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_prefix" {
  description = "Naming prefix for Dify & n8n AWS resources"
  type        = string
  default     = "dify-n8n"
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for isolated AI workflow VPC"
  type        = string
  default     = "10.40.0.0/16"
}
