# Network Module - Cost Optimized
# Supports shared NAT Gateway to reduce costs

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# VPC
# TESTING: Module change trigger - confirming both staging and production workflows detect module changes
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = length(var.public_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_cidrs[count.index]
  availability_zone = var.azs[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name        = "${var.environment}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Public Route Table Association
resource "aws_route_table_association" "public" {
  count          = length(var.public_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway (cost optimized - can be shared across environments)
resource "aws_eip" "nat" {
  count = var.create_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = {
    Name        = "${var.environment}-nat-eip"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

resource "aws_nat_gateway" "main" {
  count = var.create_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.environment}-nat-gateway"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }

  depends_on = [aws_internet_gateway.main]
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.create_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name        = "${var.environment}-private-rt"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Private Route Table Association
resource "aws_route_table_association" "private" {
  count          = length(var.private_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups - Centralized Network Security
resource "aws_security_group" "webserver" {
  name        = "${var.environment}-webserver-sg"
  description = "Security group for web servers (HTTP, SSH, egress)"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-webserver-sg"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# SSH access rule (separate to avoid conflicts)
# resource "aws_security_group_rule" "webserver_ssh_ingress" {
#   type        = "ingress"
#   from_port   = 22
#   to_port     = 22
#   protocol    = "tcp"
#   cidr_blocks = ["0.0.0.0/0"] # Consider restricting this in production
#   security_group_id = aws_security_group.webserver.id
#   description = "SSH access"
# }



# Separate security group rule to avoid circular dependency
resource "aws_security_group_rule" "webserver_alb_ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.webserver.id
  description              = "Allow HTTP traffic on port 8080 from ALB"
}

resource "aws_security_group" "database" {
  name        = "${var.environment}-database-sg"
  description = "Security group for RDS database (MySQL from webservers)"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-database-sg"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# ECS ingress rule moved to database module to avoid circular dependency



resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP traffic from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from internet"
  }

  # Allow HTTPS traffic from internet (for future SSL)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from internet"
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Separate security group rule to avoid circular dependency
resource "aws_security_group_rule" "alb_webserver_egress" {
  count = var.disable_asg ? 0 : 1  # Only create when ASG is enabled
  
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.webserver.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow outbound traffic to webservers on port 8080"
}

# ALB egress rule moved to load balancer module to avoid circular dependency

# Security group rules for ALB to webserver communication are now properly configured:
# - ALB SG allows outbound traffic to webserver SG on port 8080
# - Webserver SG allows inbound traffic from ALB SG on port 8080 