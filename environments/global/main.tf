terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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