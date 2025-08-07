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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }

  }
}

# Workspace-based environment detection
locals {
  workspace_name = terraform.workspace
  environment    = var.environment != null ? var.environment : terraform.workspace
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = local.environment
      Project     = "tf-playground"
      ManagedBy   = "terraform"
      Pipeline    = "gitflow-cicd"
      Tier        = local.environment
    }
  }
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = var.enable_eks ? module.eks[0].cluster_endpoint : null
  cluster_ca_certificate = var.enable_eks ? base64decode(module.eks[0].cluster_certificate_authority_data) : null
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.enable_eks ? module.eks[0].cluster_name : ""]
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

  environment   = local.environment
  vpc_cidr      = var.vpc_cidr
  public_cidrs  = var.public_subnet_cidrs
  private_cidrs = var.private_subnet_cidrs
  azs           = var.availability_zones
  enable_ecs    = var.enable_ecs
  # ecs_tasks_security_group_id = local.ecs_tasks_security_group_id  # Moved to individual modules
  enable_asg    = var.enable_asg
  enable_eks    = var.enable_eks
  
  # Environment pattern variables for networking logic
  enable_private_subnets = var.enable_private_subnets
  enable_nat_gateway     = var.enable_nat_gateway
  create_nat_gateway     = var.create_nat_gateway
}

# Centralized Parameter Store Configuration
locals {
  db_password_parameter_name  = "/tf-playground/all/db-password"
  ssh_private_key_secret_name = "/tf-playground/all/ssh-key"
  ssh_public_key_secret_name  = "/tf-playground/all/ssh-key-public"
  
  # ECS Tasks Security Group ID (for database access)
  ecs_tasks_security_group_id = (var.enable_platform && var.enable_ecs) ? module.ecs[0].ecs_tasks_security_group_id : null
}

# Get centralized database password from Parameter Store (only when RDS is enabled)
data "aws_ssm_parameter" "db_password" {
  count           = var.enable_rds ? 1 : 0
  name            = local.db_password_parameter_name
  with_decryption = true
}

# Get centralized SSH private key
data "aws_secretsmanager_secret" "ssh_private" {
  name = local.ssh_private_key_secret_name
}

data "aws_secretsmanager_secret_version" "ssh_private" {
  secret_id = data.aws_secretsmanager_secret.ssh_private.id
}

# Get centralized SSH public key
data "aws_secretsmanager_secret" "ssh_public" {
  count = var.enable_platform && (var.enable_ecs || var.enable_eks) ? 1 : 0
  name  = local.ssh_public_key_secret_name
}

data "aws_secretsmanager_secret_version" "ssh_public" {
  count     = var.enable_platform && (var.enable_ecs || var.enable_eks) ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.ssh_public[0].id
}

# Create environment-specific AWS key pair using centralized SSH public key
resource "aws_key_pair" "environment_key" {
  count = var.enable_platform && (var.enable_ecs || var.enable_eks) ? 1 : 0
  
  key_name   = "tf-playground-${local.environment}-key"
  public_key = data.aws_secretsmanager_secret_version.ssh_public[0].secret_string

  tags = {
    Name        = "tf-playground-${local.environment}-key"
    Environment = local.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
    Purpose     = "centralized-ssh-key"
  }
}

# Application Load Balancer Module (conditionally created)
module "loadbalancer" {
  count = var.enable_platform && (var.enable_asg || var.enable_ecs) ? 1 : 0
  source = "../../modules/loadbalancer"

  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnets    = module.networking.public_subnet_ids
  certificate_arn   = var.certificate_arn
  security_group_id = module.networking.alb_security_group_id
  waf_web_acl_arn   = var.environment_waf_use ? try(data.terraform_remote_state.global.outputs.waf_web_acl_arn, null) : null
  target_type       = var.enable_ecs ? "ip" : "instance"
  create_green_listener_rule = var.enable_ecs
  enable_ecs        = var.enable_ecs
  ecs_tasks_security_group_id = local.ecs_tasks_security_group_id
  enable_eks        = false  # EKS environments don't use ALB
  eks_pods_security_group_id = module.networking.eks_pods_security_group_id
}

# Database Module (conditionally created)
module "database" {
  count = var.enable_rds ? 1 : 0
  source            = "../../modules/database"
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  private_subnets   = module.networking.private_subnet_ids
  public_subnets    = module.networking.public_subnet_ids
  
  # Environment pattern variables
  enable_private_subnets = var.enable_private_subnets
  enable_nat_gateway     = var.enable_nat_gateway
  
  db_instance_type  = var.db_instance_type
  db_name           = var.db_name
  db_username       = "tfplayground_user"
  db_password       = data.aws_ssm_parameter.db_password[0].value
  security_group_id = module.networking.database_security_group_id
  enable_ecs        = var.enable_ecs
  ecs_tasks_security_group_id = local.ecs_tasks_security_group_id
  enable_asg        = var.enable_asg
  webserver_security_group_id = module.networking.webserver_security_group_id
  enable_eks        = var.enable_eks
  eks_pods_security_group_id = module.networking.eks_pods_security_group_id
  eks_nodes_security_group_id = module.networking.eks_nodes_security_group_id
  eks_cluster_security_group_id = var.enable_eks ? module.eks[0].cluster_security_group_id : ""
}

# Blue Auto Scaling Group (conditionally created)
module "blue_asg" {
  count  = var.enable_platform && var.enable_asg ? 1 : 0
  source = "../../modules/compute/asg"

  environment           = var.environment
  deployment_color      = "blue"
  vpc_id                = module.networking.vpc_id
  subnet_ids            = module.networking.public_subnet_ids
  alb_security_group_id = (var.enable_platform && var.enable_asg) ? module.loadbalancer[0].alb_security_group_id : null
  target_group_arn      = (var.enable_platform && var.enable_asg) ? module.loadbalancer[0].blue_target_group_arn : null
  instance_type         = var.webserver_instance_type
  ami_id                = var.ami_id
  desired_capacity      = var.blue_desired_capacity
  max_size              = var.blue_max_size
  min_size              = var.blue_min_size
  db_host               = var.enable_rds ? module.database[0].db_instance_address : ""
  db_name               = var.db_name
  db_user               = "tfplayground_user"
  db_password           = var.enable_rds ? data.aws_ssm_parameter.db_password[0].value : ""
  security_group_id     = module.networking.webserver_security_group_id
  key_name              = length(aws_key_pair.environment_key) > 0 ? aws_key_pair.environment_key[0].key_name : null
  application_log_group_name = data.terraform_remote_state.global.outputs.application_log_groups[var.environment]
  system_log_group_name      = data.terraform_remote_state.global.outputs.system_log_groups[var.environment]
}

# Green Auto Scaling Group (conditionally created)
module "green_asg" {
  count  = var.enable_platform && var.enable_asg ? 1 : 0
  source = "../../modules/compute/asg"

  environment           = var.environment
  deployment_color      = "green"
  vpc_id                = module.networking.vpc_id
  subnet_ids            = module.networking.public_subnet_ids
  alb_security_group_id = (var.enable_platform && var.enable_asg) ? module.loadbalancer[0].alb_security_group_id : null
  target_group_arn      = (var.enable_platform && var.enable_asg) ? module.loadbalancer[0].green_target_group_arn : null
  instance_type         = var.webserver_instance_type
  ami_id                = var.ami_id
  desired_capacity      = var.green_desired_capacity
  max_size              = var.green_max_size
  min_size              = var.green_min_size
  db_host               = var.enable_rds ? module.database[0].db_instance_address : ""
  db_name               = var.db_name
  db_user               = "tfplayground_user"
  db_password           = var.enable_rds ? data.aws_ssm_parameter.db_password[0].value : ""
  security_group_id     = module.networking.webserver_security_group_id
  key_name              = length(aws_key_pair.environment_key) > 0 ? aws_key_pair.environment_key[0].key_name : null
  application_log_group_name = data.terraform_remote_state.global.outputs.application_log_groups[var.environment]
  system_log_group_name      = data.terraform_remote_state.global.outputs.system_log_groups[var.environment]
}

# SSM Module for Database Bootstrapping (conditionally created)
module "ssm" {
  count                 = var.enable_platform && var.enable_asg && var.enable_rds ? 1 : 0
  source                = "../../modules/ssm"
  environment           = var.environment
  webserver_instance_id = module.blue_asg[0].asg_id
  webserver_public_ip   = (var.enable_platform && var.enable_asg) ? module.loadbalancer[0].alb_dns_name : null
  database_endpoint     = module.database[0].db_instance_address
  database_name         = var.db_name
  database_username     = "tfplayground_user"
  database_password     = data.aws_ssm_parameter.db_password[0].value
}

# EKS Module (conditionally created)
module "eks" {
  count  = var.enable_platform && var.enable_eks ? 1 : 0
  source = "../../modules/eks"

  environment = var.environment
  cluster_name = "${var.environment}-eks-cluster"
  vpc_id = module.networking.vpc_id
  
  # Subnet selection logic based on environment pattern:
  # - Dev: Public subnets (no NAT needed)
  # - Staging/Production: Private subnets (with NAT Gateway)
  subnet_ids = module.networking.eks_subnet_ids
  
  # EKS configuration
  enable_node_groups = var.enable_node_groups
  enable_fargate = var.enable_fargate
  enable_monitoring = var.enable_monitoring
  enable_alb_controller = var.enable_alb_controller
  
  # Security groups
  eks_nodes_security_group_id = module.networking.eks_nodes_security_group_id
  eks_pods_security_group_id = module.networking.eks_pods_security_group_id
  
  # Node group configuration
  node_group_instance_types = var.node_group_instance_types
  node_group_desired_size = var.node_group_desired_size
  node_group_max_size = var.node_group_max_size
  node_group_min_size = var.node_group_min_size
}

# Logging Module
module "logging" {
  source = "../../modules/logging"

  environment    = var.environment
  aws_region     = var.aws_region
  alb_name       = var.enable_platform && (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_name : null
  alb_identifier = var.enable_platform && (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_identifier : null

  # Use log group names from global environment
  application_log_group_name = data.terraform_remote_state.global.outputs.application_log_groups[var.environment]
  system_log_group_name      = data.terraform_remote_state.global.outputs.system_log_groups[var.environment]
  alarm_log_group_name       = data.terraform_remote_state.global.outputs.alarm_log_groups[var.environment]
}

# ALB-to-ECS Security Group Rule (created after both modules exist)
# Note: ECS module not yet implemented, this rule is disabled
# resource "aws_security_group_rule" "alb_ecs_tasks_egress" {
#   count                    = var.enable_ecs ? 1 : 0
#   type                     = "egress"
#   from_port                = 8080
#   to_port                  = 8080
#   protocol                 = "tcp"
#   source_security_group_id = module.ecs[0].ecs_tasks_security_group_id
#   security_group_id        = module.networking.alb_security_group_id
#   description              = "Allow outbound traffic to ECS tasks on port 8080"
# }

# Kubernetes Resources (when EKS is enabled)
locals {
  ecr_repository_url = data.terraform_remote_state.global.outputs.ecr_repository_url
}

# Note: Database password from Parameter Store is defined above for all modules

# Note: EKS node group information is available via module.eks[0].node_group_id
# No need for data source since we're creating the node group in the same configuration

# Kubernetes Secret for Database Password (only when both EKS and RDS are enabled)
resource "kubernetes_secret" "db_password" {
  count = (var.enable_platform && var.enable_eks && var.enable_rds) ? 1 : 0
  
  metadata {
    name = "db-password"
  }
  
  data = {
    password = data.aws_ssm_parameter.db_password[0].value
  }
}

# Flask Application Deployment
resource "kubernetes_deployment" "flask_app" {
  count = var.enable_platform && var.enable_eks ? 1 : 0
  
  metadata {
    name = "${var.environment}-flask-app"
    labels = {
      app = "flask-app"
      environment = var.environment
    }
  }
  
  spec {
    replicas = var.flask_app_replicas
    
    selector {
      match_labels = {
        app = "flask-app"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "flask-app"
          environment = var.environment
        }
      }
      
      spec {
        container {
          name  = "flask-app"
          image = "${local.ecr_repository_url}:${var.image_tag}"
          
          port {
            container_port = 8080
          }
          
          env {
            name  = "DB_HOST"
            value = var.enable_rds ? module.database[0].db_instance_address : ""
          }
          
          env {
            name  = "DB_PORT"
            value = "3306"
          }
          
          env {
            name  = "DB_NAME"
            value = var.db_name
          }
          
          env {
            name  = "DB_USER"
            value = "tfplayground_user"
          }
          
          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_password[0].metadata[0].name
                key  = "password"
              }
            }
          }
          
          resources {
            requests = {
              memory = var.flask_memory_request
              cpu    = var.flask_cpu_request
            }
            limits = {
              memory = var.flask_memory_limit
              cpu    = var.flask_cpu_limit
            }
          }
        }
      }
    }
  }
}

# Flask Application Service
resource "kubernetes_service" "flask_app" {
  count = var.enable_platform && var.enable_eks ? 1 : 0
  
  metadata {
    name = "${var.environment}-flask-app-service"
  }
  
  spec {
    selector = {
      app = "flask-app"
    }
    
    port {
      protocol    = "TCP"
      port        = 8080
      target_port = 8080
    }
    
    type = "LoadBalancer"
  }
}

# Note: Ingress resource removed - using LoadBalancer service type only
# This avoids dependency on AWS Load Balancer Controller
# The LoadBalancer service type automatically provisions a Classic ELB





 