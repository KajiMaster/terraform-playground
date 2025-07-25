# Security group is now managed by the networking module

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
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.database.name

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  multi_az            = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.environment}-database"
  }
} 