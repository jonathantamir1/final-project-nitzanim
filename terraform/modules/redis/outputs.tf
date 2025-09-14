# Redis Module - Outputs
# This file defines the outputs for the Redis module

output "endpoint" {
  description = "Redis cluster endpoint"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "port" {
  description = "Redis cluster port"
  value       = aws_elasticache_replication_group.main.port
}

output "replication_group_id" {
  description = "Redis replication group ID"
  value       = aws_elasticache_replication_group.main.replication_group_id
}

output "replication_group_arn" {
  description = "Redis replication group ARN"
  value       = aws_elasticache_replication_group.main.arn
}

output "cluster_enabled" {
  description = "Whether cluster mode is enabled"
  value       = aws_elasticache_replication_group.main.cluster_enabled
}
