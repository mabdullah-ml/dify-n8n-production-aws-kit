locals {
  common_tags = {
    Project     = var.project_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

data "aws_caller_identity" "current" {}

# ── Isolated VPC & Subnets ───────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(local.common_tags, { Name = "${var.project_prefix}-vpc" })
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone = "${var.aws_region}a"
  tags              = merge(local.common_tags, { Name = "${var.project_prefix}-priv-a" })
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone = "${var.aws_region}c"
  tags              = merge(local.common_tags, { Name = "${var.project_prefix}-priv-c" })
}

# ── Encrypted S3 Storage for Dify Knowledge Uploads & n8n Binary Artifacts ───
resource "aws_s3_bucket" "storage" {
  bucket = "${var.project_prefix}-storage-${data.aws_caller_identity.current.account_id}-${var.environment}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket                  = aws_s3_bucket.storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── AWS Secrets Manager for Dify & n8n Encryption Keys ───────────────────────
resource "aws_secretsmanager_secret" "dify_secret_key" {
  name = "${var.project_prefix}/${var.environment}/dify-secret-key"
  tags = local.common_tags
}

resource "aws_secretsmanager_secret" "n8n_encryption_key" {
  name = "${var.project_prefix}/${var.environment}/n8n-encryption-key"
  tags = local.common_tags
}

# ── Aurora PostgreSQL Serverless v2 Cluster ──────────────────────────────────
resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_prefix}-db-subnets-${var.environment}"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_c.id]
  tags       = local.common_tags
}

resource "aws_rds_cluster" "platform_db" {
  cluster_identifier          = "${var.project_prefix}-aurora-${var.environment}"
  engine                      = "aurora-postgresql"
  engine_mode                 = "provisioned"
  engine_version              = "16.4"
  database_name               = "dify_n8n_platform"
  master_username             = "aiops_admin"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.aurora.name
  storage_encrypted           = true
  skip_final_snapshot         = false
  tags                        = local.common_tags

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4.0
  }
}

# ── ECS Cluster & Least-Privilege Execution Role ─────────────────────────────
resource "aws_ecs_cluster" "platform" {
  name = "${var.project_prefix}-ecs-${var.environment}"
  tags = local.common_tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_prefix}-ecs-exec-${var.environment}"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
