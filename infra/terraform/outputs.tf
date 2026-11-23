output "vpc_id" {
  description = "Isolated VPC hosting Dify & n8n services"
  value       = aws_vpc.main.id
}

output "ecs_cluster_name" {
  description = "ECS cluster name for self-hosted Dify & n8n containers"
  value       = aws_ecs_cluster.platform.name
}

output "storage_bucket_name" {
  description = "Encrypted S3 storage bucket for RAG uploads and workflow artifacts"
  value       = aws_s3_bucket.storage.id
}

output "aurora_cluster_endpoint" {
  description = "Aurora PostgreSQL Serverless v2 writer endpoint"
  value       = aws_rds_cluster.platform_db.endpoint
}
