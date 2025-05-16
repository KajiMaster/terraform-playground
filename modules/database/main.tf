# Security Group for RDS
resource "aws_security_group" "database" {
  name        = "${var.environment}-database-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  # Allow MySQL access from web server security group
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.webserver_security_group_id]
    description     = "Allow MySQL access from web server"
  }

  tags = {
    Name = "${var.environment}-database-sg"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "database" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

# RDS Instance
resource "aws_db_instance" "database" {
  identifier           = "${var.environment}-db"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = var.db_instance_type
  allocated_storage   = 20
  storage_type        = "gp3"
  storage_encrypted   = true

  db_name             = var.db_name
  username            = var.db_username
  password            = var.db_password

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.database.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  multi_az               = false
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = {
    Name = "${var.environment}-database"
  }
}

# Initial database setup
resource "null_resource" "database_setup" {
  depends_on = [aws_db_instance.database]

  provisioner "local-exec" {
    command = <<-EOF
      mysql -h ${aws_db_instance.database.address} \
            -u ${var.db_username} \
            -p${var.db_password} \
            ${var.db_name} \
            -e "
      CREATE TABLE IF NOT EXISTS contacts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        address VARCHAR(200),
        phone VARCHAR(20)
      );

      INSERT INTO contacts (name, address, phone) VALUES
        ('John Doe', '123 Main St, City, State', '555-0101'),
        ('Jane Smith', '456 Oak Ave, Town, State', '555-0102'),
        ('Bob Johnson', '789 Pine Rd, Village, State', '555-0103'),
        ('Alice Brown', '321 Elm St, City, State', '555-0104'),
        ('Charlie Wilson', '654 Maple Dr, Town, State', '555-0105');
      "
    EOF
  }
} 