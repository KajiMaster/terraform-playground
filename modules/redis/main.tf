terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name        = "${var.environment}-redis-subnet-group"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Security group rule for Redis access from ECS
resource "aws_security_group_rule" "redis_ecs_ingress" {
  count = var.enable_ecs ? 1 : 0

  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = var.ecs_tasks_security_group_id
  security_group_id        = var.security_group_id
  description              = "Allow ECS tasks to access Redis on port 6379"
}

# ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id         = "${var.environment}-redis"
  description                  = "Redis cluster for ${var.environment} environment"
  
  port                         = 6379
  parameter_group_name         = aws_elasticache_parameter_group.redis.name
  node_type                    = var.node_type
  num_cache_clusters           = var.num_cache_nodes
  
  engine_version               = "7.0"
  subnet_group_name            = aws_elasticache_subnet_group.redis.name
  security_group_ids           = [var.security_group_id]
  
  at_rest_encryption_enabled   = true
  transit_encryption_enabled   = true
  auth_token                   = var.auth_token
  
  # Backup configuration
  snapshot_retention_limit     = 7
  snapshot_window              = "03:00-05:00"
  maintenance_window           = "sun:05:00-sun:07:00"
  
  # Automatic failover for multi-AZ
  automatic_failover_enabled   = var.num_cache_nodes > 1 ? true : false
  multi_az_enabled             = var.num_cache_nodes > 1 ? true : false
  
  # Logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  tags = {
    Name        = "${var.environment}-redis"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Redis Parameter Group for optimization
resource "aws_elasticache_parameter_group" "redis" {
  family = "redis7.x"
  name   = "${var.environment}-redis-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"  # Evict least recently used keys when memory limit reached
  }

  parameter {
    name  = "timeout"
    value = "300"  # Client idle timeout in seconds
  }

  parameter {
    name  = "tcp-keepalive"
    value = "60"   # TCP keepalive
  }

  parameter {
    name  = "maxclients"
    value = "1000"  # Maximum number of clients
  }

  tags = {
    Name        = "${var.environment}-redis-params"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# CloudWatch Log Group for Redis slow logs
resource "aws_cloudwatch_log_group" "redis_slow" {
  name              = "/aws/elasticache/redis/${var.environment}/slow-log"
  retention_in_days = 7

  tags = {
    Name        = "${var.environment}-redis-logs"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}