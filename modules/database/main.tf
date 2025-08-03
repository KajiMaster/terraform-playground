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

# EKS pods ingress rule for database access
resource "aws_security_group_rule" "database_eks_pods_ingress" {
  count = var.enable_eks ? 1 : 0

  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = var.eks_pods_security_group_id
  security_group_id        = var.security_group_id
  description              = "Allow EKS pods to access database on port 3306"
}

# EKS nodes ingress rule for database access (pods may use node's security group for outbound traffic)
resource "aws_security_group_rule" "database_eks_nodes_ingress" {
  count = var.enable_eks ? 1 : 0

  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = var.eks_nodes_security_group_id
  security_group_id        = var.security_group_id
  description              = "Allow EKS nodes to access database on port 3306"
}

# EKS cluster ingress rule for database access (AWS-managed cluster security group)
resource "aws_security_group_rule" "database_eks_cluster_ingress" {
  count = var.enable_eks ? 1 : 0

  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = var.eks_cluster_security_group_id
  security_group_id        = var.security_group_id
  description              = "Allow EKS cluster security group to access database on port 3306"
}

# DB Subnet Group
# Environment pattern logic:
# - Dev: Use public subnets (no private subnets, no NAT)
# - Staging/Production: Use private subnets (enterprise pattern)
resource "aws_db_subnet_group" "database" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.enable_private_subnets ? var.private_subnets : var.public_subnets

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
  
  # Environment pattern logic:
  # - Dev: publicly_accessible = true (public subnets, direct access)
  # - Staging/Production: publicly_accessible = false (private subnets)
  publicly_accessible = var.enable_private_subnets ? false : true

  tags = {
    Name = "${var.environment}-database"
  }
}

 