terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.50.0"
    }
  }
}

provider "tfe" {
  # Token should be set via TFE_TOKEN environment variable
  # export TFE_TOKEN=your-token-here
}

# Get the workspace
data "tfe_workspace" "terraform_playground" {
  name         = "terraform-playground-dev"
  organization = "ve-tfcloud-refresh"
}

# Environment Variables (sensitive)
resource "tfe_variable" "aws_access_key" {
  key          = "AWS_ACCESS_KEY_ID"
  value        = var.aws_access_key
  category     = "env"
  sensitive    = true
  workspace_id = data.tfe_workspace.terraform_playground.id
}

resource "tfe_variable" "aws_secret_key" {
  key          = "AWS_SECRET_ACCESS_KEY"
  value        = var.aws_secret_key
  category     = "env"
  sensitive    = true
  workspace_id = data.tfe_workspace.terraform_playground.id
}

# Terraform Variables
resource "tfe_variable" "environment" {
  key          = "environment"
  value        = var.environment
  category     = "terraform"
  workspace_id = data.tfe_workspace.terraform_playground.id
}

resource "tfe_variable" "aws_region" {
  key          = "aws_region"
  value        = var.aws_region
  category     = "terraform"
  workspace_id = data.tfe_workspace.terraform_playground.id
}

resource "tfe_variable" "vpc_cidr" {
  key          = "vpc_cidr"
  value        = var.vpc_cidr
  category     = "terraform"
  workspace_id = data.tfe_workspace.terraform_playground.id
}

resource "tfe_variable" "public_subnet_cidrs" {
  key          = "public_subnet_cidrs"
  value        = jsonencode(var.public_subnet_cidrs)
  category     = "terraform"
  workspace_id = data.tfe_workspace.terraform_playground.id
}

resource "tfe_variable" "private_subnet_cidrs" {
  key          = "private_subnet_cidrs"
  value        = jsonencode(var.private_subnet_cidrs)
  category     = "terraform"
  workspace_id = data.tfe_workspace.terraform_playground.id
}

resource "tfe_variable" "availability_zones" {
  key          = "availability_zones"
  value        = jsonencode(var.availability_zones)
  category     = "terraform"
  workspace_id = data.tfe_workspace.terraform_playground.id
}

resource "tfe_variable" "webserver_instance_type" {
  key          = "webserver_instance_type"
  value        = var.webserver_instance_type
  category     = "terraform"
  workspace_id = data.tfe_workspace.terraform_playground.id
}

resource "tfe_variable" "key_name" {
  key          = "key_name"
  value        = var.key_name
  category     = "terraform"
  workspace_id = data.tfe_workspace.terraform_playground.id
}

resource "tfe_variable" "db_instance_type" {
  key          = "db_instance_type"
  value        = var.db_instance_type
  category     = "terraform"
  workspace_id = data.tfe_workspace.terraform_playground.id
}

resource "tfe_variable" "db_name" {
  key          = "db_name"
  value        = var.db_name
  category     = "terraform"
  workspace_id = data.tfe_workspace.terraform_playground.id
} 