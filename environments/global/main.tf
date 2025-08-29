terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "tf-playground-state-vexus"
    key            = "global/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = false
  }
}

provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Environment = "global"
      Project     = "tf-playground"
      ManagedBy   = "terraform"
      Purpose     = "global-resources"
    }
  }
}

# Global OIDC Provider for GitHub Actions
module "oidc" {
  source = "../../modules/oidc"

  environment          = "global"
  github_repository    = "KajiMaster/terraform-playground"
  state_bucket         = "tf-playground-state-vexus"
  state_lock_table     = "tf-playground-locks"
  aws_region           = "us-east-2"
  create_oidc_provider = true
}

# Global CloudWatch Log Groups - Shared across environments
module "log_groups" {
  source = "../../modules/log-groups"

  log_retention_days = 1 # Demo environment - 1 day retention
}

# Global WAF - Shared across environments
module "waf" {
  source = "../../modules/waf"

  enable_waf           = var.enable_waf
  enable_logging       = var.enable_logging
  rate_limit           = var.waf_rate_limit
  enable_ip_reputation = var.enable_ip_reputation
  blocked_paths        = var.waf_blocked_paths
  log_retention_days   = var.waf_log_retention_days
}

# Global ECR Repository - Shared across environments
module "ecr" {
  source = "../../modules/ecr"

  environment = "global"
  app_name    = "tf-pg-ecr"
  tags = {
    Purpose = "shared-container-registry"
  }
}

# Shared SSM Parameter for Claude API Key
# Used by multiple projects for GitHub Actions Claude Code reviews
resource "aws_ssm_parameter" "claude_api_key" {
  name        = "/global/claude-code/api-key"
  type        = "SecureString"
  description = "Anthropic API key for Claude Code reviews across all projects"
  
  # Placeholder value - update this after creation via AWS CLI or Console
  value = "PLACEHOLDER_UPDATE_VIA_AWS_CONSOLE"

  # Ignore changes to the value to preserve the existing secret
  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name        = "claude-code-api-key"
    Environment = "global"
    Purpose     = "github-actions-claude-reviews"
    ManagedBy   = "terraform"
    Project     = "shared-infrastructure"
  }
} 