terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = "${var.environment}"
      Project     = "tf-playground"
      ManagedBy   = "terraform"
      Pipeline    = "gitflow-cicd"
      Tier        = "development"
    }
  }
}

# Remote state data source for global OIDC provider
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "tf-playground-state-vexus"
    key    = "global/terraform.tfstate"
    region = "us-east-2"
  }
}

# Network Module
module "networking" {
  source = "../../modules/networking"

  environment   = var.environment
  vpc_cidr      = var.vpc_cidr
  public_cidrs  = var.public_subnet_cidrs
  private_cidrs = var.private_subnet_cidrs
  azs           = var.availability_zones
}

# Centralized SSH Keys Module
module "ssh_keys" {
  source      = "../../modules/ssh-keys"
  environment = var.environment
}

# Application Load Balancer Module
module "loadbalancer" {
  source = "../../modules/loadbalancer"

  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnets    = module.networking.public_subnet_ids
  certificate_arn   = var.certificate_arn
  security_group_id = module.networking.alb_security_group_id
}

# Database Module
module "database" {
  source            = "../../modules/database"
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  private_subnets   = module.networking.private_subnet_ids
  db_instance_type  = var.db_instance_type
  db_name           = var.db_name
  db_username       = data.terraform_remote_state.global.outputs.db_username
  db_password       = data.terraform_remote_state.global.outputs.db_password
  security_group_id = module.networking.database_security_group_id
}

# Blue Auto Scaling Group
module "blue_asg" {
  source = "../../modules/compute/asg"

  environment           = var.environment
  deployment_color      = "blue"
  vpc_id                = module.networking.vpc_id
  subnet_ids            = module.networking.public_subnet_ids
  alb_security_group_id = module.loadbalancer.alb_security_group_id
  target_group_arn      = module.loadbalancer.blue_target_group_arn
  instance_type         = var.webserver_instance_type
  ami_id                = var.ami_id
  desired_capacity      = var.blue_desired_capacity
  max_size              = var.blue_max_size
  min_size              = var.blue_min_size
  db_host               = module.database.db_instance_address
  db_name               = var.db_name
  db_user               = data.terraform_remote_state.global.outputs.db_username
  db_password           = data.terraform_remote_state.global.outputs.db_password
  security_group_id     = module.networking.webserver_security_group_id
  key_name              = module.ssh_keys.key_name
}

# Green Auto Scaling Group
module "green_asg" {
  source = "../../modules/compute/asg"

  environment           = var.environment
  deployment_color      = "green"
  vpc_id                = module.networking.vpc_id
  subnet_ids            = module.networking.public_subnet_ids
  alb_security_group_id = module.loadbalancer.alb_security_group_id
  target_group_arn      = module.loadbalancer.green_target_group_arn
  instance_type         = var.webserver_instance_type
  ami_id                = var.ami_id
  desired_capacity      = var.green_desired_capacity
  max_size              = var.green_max_size
  min_size              = var.green_min_size
  db_host               = module.database.db_instance_address
  db_name               = var.db_name
  db_user               = data.terraform_remote_state.global.outputs.db_username
  db_password           = data.terraform_remote_state.global.outputs.db_password
  security_group_id     = module.networking.webserver_security_group_id
  key_name              = module.ssh_keys.key_name
}

# SSM Module for Database Bootstrapping (updated to use blue ASG)
module "ssm" {
  source                = "../../modules/ssm"
  environment           = var.environment
  webserver_instance_id = module.blue_asg.asg_id           # Will need to get actual instance ID
  webserver_public_ip   = module.loadbalancer.alb_dns_name # Use ALB DNS name instead
  database_endpoint     = module.database.db_instance_address
  database_name         = var.db_name
  database_username     = data.terraform_remote_state.global.outputs.db_username
  database_password     = data.terraform_remote_state.global.outputs.db_password
} 