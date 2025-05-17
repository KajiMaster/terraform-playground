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
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "tf-playground-${var.environment}-vpc"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "tf-playground-${var.environment}-igw"
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

  tags = {
    Name        = "tf-playground-${var.environment}-public-${count.index + 1}"
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
    Name        = "tf-playground-${var.environment}-private-${count.index + 1}"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "tf-playground-${var.environment}-nat-eip"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id  # Place NAT Gateway in first public subnet

  tags = {
    Name        = "tf-playground-${var.environment}-nat"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "tf-playground-${var.environment}-public-rt"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "tf-playground-${var.environment}-private-rt"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
} 