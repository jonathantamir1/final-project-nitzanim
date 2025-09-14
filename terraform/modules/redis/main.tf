# Redis Module - ElastiCache Redis
# This module creates the ElastiCache Redis cluster for the Status Page application

# Redis Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnets

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redis-subnet-group"
  })
}

# Redis Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  family = "redis7.x"
  name   = "${var.project_name}-${var.environment}-redis-parameter-group"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = var.tags
}

# Redis Cluster
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.project_name}-${var.environment}-redis"
  description                = "Redis cluster for ${var.project_name}-${var.environment}"

  # Node configuration
  node_type                  = var.node_type
  port                       = 6379
  parameter_group_name       = aws_elasticache_parameter_group.main.name
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [var.redis_security_group_id]

  # Cluster configuration
  num_cache_clusters         = 2  # Cost optimization: minimal nodes
  automatic_failover_enabled = true
  multi_az_enabled          = true

  # Engine configuration
  engine_version = "7.0"

  # Backup configuration
  snapshot_retention_limit = 3  # Cost optimization: minimal retention
  snapshot_window         = "03:00-05:00"
  maintenance_window      = "sun:05:00-sun:07:00"

  # Logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  # Deletion protection
  apply_immediately = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redis"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "redis" {
  name              = "/aws/elasticache/redis/${var.project_name}-${var.environment}"
  retention_in_days = 7  # Cost optimization: minimal retention

  tags = var.tags
}
