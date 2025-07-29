# Security group is now managed by the networking module

# ECS ingress rule for database access
resource "aws_security_group_rule" "database_ecs_ingress" {
  count = var.enable_ecs ? 1 : 0

  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = var.ecs_tasks_security_group_id
  security_group_id        = var.security_group_id
  description              = "Allow ECS tasks to access database on port 3306"
}

# Webserver ingress rule for database access (when ASG is enabled)
resource "aws_security_group_rule" "database_webserver_ingress" {
  count = var.enable_asg ? 1 : 0

  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = var.webserver_security_group_id
  security_group_id        = var.security_group_id
  description              = "Allow webservers to access database on port 3306"
}

# DB Subnet Group
resource "aws_db_subnet_group" "database" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Instance
resource "aws_db_instance" "database" {
  identifier        = "${var.environment}-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_type
  allocated_storage     = 20
  max_allocated_storage = 100  # Enable storage autoscaling
  storage_type          = "gp3"
  storage_encrypted     = true
  iops                  = 3000  # Baseline for gp3
  storage_throughput    = 125   # Baseline for gp3

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.database.name

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Performance Insights for monitoring
  performance_insights_enabled    = true
  performance_insights_retention_period = 7

  # Enhanced monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # Connection limits and parameters
  parameter_group_name = aws_db_parameter_group.database.name

  multi_az            = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.environment}-database"
  }
}

# DB Parameter Group for optimization
resource "aws_db_parameter_group" "database" {
  family = "mysql8.0"
  name   = "${var.environment}-db-params"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"  # Use 75% of available memory
  }

  parameter {
    name  = "max_connections"
    value = "200"  # Adjust based on your connection pool size
  }

  parameter {
    name  = "innodb_flush_log_at_trx_commit"
    value = "2"  # Better performance, slight durability trade-off
  }

  parameter {
    name  = "query_cache_type"
    value = "1"
  }

  parameter {
    name  = "query_cache_size"
    value = "67108864"  # 64MB
  }

  tags = {
    Name = "${var.environment}-db-params"
  }
}

# IAM role for RDS enhanced monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.environment}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-rds-enhanced-monitoring"
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
} 