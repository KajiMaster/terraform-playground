# Terraform Workspaces Architecture Proposal

## Problem Statement

The current architecture has several issues:
1. **Environment Root Module Duplication**: Three nearly identical `main.tf` files
2. **Branch-Environment Mismatch**: Can deploy any environment from any branch
3. **Module Versioning Risk**: No way to test module changes safely
4. **State File Conflicts**: Multiple branches can target the same state

## Solution: Terraform Workspaces

### Architecture Overview

```
Single Root Module (environments/base/)
├── Workspace: dev
├── Workspace: staging  
└── Workspace: production
```

### Benefits

1. **Eliminates Duplication**: One root module, multiple workspaces
2. **Enforces Branch-Environment Mapping**: CI/CD controls which workspace gets deployed
3. **Isolated State Files**: Each workspace has its own state
4. **Consistent Module Versions**: All workspaces use same module versions

### Implementation

#### 1. Create Single Root Module

```bash
# Move to single root module
mkdir -p environments/base
mv environments/dev/* environments/base/
rmdir environments/dev environments/staging environments/production
```

#### 2. Workspace Configuration

```hcl
# environments/base/main.tf
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Dynamic environment based on workspace
locals {
  workspace = terraform.workspace
  environment = local.workspace
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = local.environment
      Project     = "tf-playground"
      ManagedBy   = "terraform"
      Workspace   = local.workspace
    }
  }
}

# Use workspace-specific variables
module "networking" {
  source = "../../modules/networking"
  
  environment   = local.environment
  vpc_cidr      = var.vpc_cidrs[local.environment]
  public_cidrs  = var.public_subnet_cidrs[local.environment]
  private_cidrs = var.private_subnet_cidrs[local.environment]
  azs           = var.availability_zones
}
```

#### 3. Workspace-Specific Variables

```hcl
# environments/base/variables.tf
variable "vpc_cidrs" {
  description = "VPC CIDR blocks per environment"
  type = map(string)
  default = {
    dev        = "192.168.1.0/24"
    staging    = "192.168.2.0/24"
    production = "192.168.3.0/24"
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks per environment"
  type = map(list(string))
  default = {
    dev        = ["192.168.1.0/26", "192.168.1.64/26"]
    staging    = ["192.168.2.0/26", "192.168.2.64/26"]
    production = ["192.168.3.0/26", "192.168.3.64/26"]
  }
}
```

#### 4. Backend Configuration

```hcl
# environments/base/backend.tf
terraform {
  backend "s3" {
    bucket         = "tf-playground-state-vexus"
    key            = "base/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = false
  }
}
```

#### 5. CI/CD Workspace Management

```yaml
# .github/workflows/staging-terraform.yml
- name: Terraform Init
  working-directory: environments/base
  run: terraform init

- name: Select Workspace
  working-directory: environments/base
  run: terraform workspace select staging || terraform workspace new staging

- name: Terraform Apply
  working-directory: environments/base
  run: terraform apply -auto-approve
```

### Branch-Environment Enforcement

#### GitFlow with Workspaces

```yaml
# Branch → Workspace Mapping
develop branch → staging workspace
main branch → production workspace
feature branches → dev workspace
```

#### CI/CD Triggers

```yaml
# .github/workflows/staging-terraform.yml
on:
  push:
    branches: [develop]
    paths:
      - 'environments/base/**'
      - 'modules/**'
      - '!modules/oidc/**'

# .github/workflows/prod-terraform.yml  
on:
  push:
    branches: [main]
    paths:
      - 'environments/base/**'
      - 'modules/**'
      - '!modules/oidc/**'
```

### Module Versioning Strategy

#### Option A: Git Tags for Module Versions

```hcl
# Use specific module versions
module "networking" {
  source = "git::https://github.com/your-org/terraform-modules.git//networking?ref=v1.2.0"
  # ... variables
}
```

#### Option B: Terraform Registry

```hcl
# Use Terraform Registry
module "networking" {
  source  = "your-org/networking/aws"
  version = "~> 1.2"
  # ... variables
}
```

#### Option C: Local Module Versioning

```hcl
# Use local modules with version constraints
module "networking" {
  source = "../../modules/networking"
  version = "1.2.0"  # Would need to implement versioning
  # ... variables
}
```

### Migration Strategy

#### Phase 1: Create Workspace Structure
1. Create `environments/base/` directory
2. Move common configuration to base
3. Create workspace-specific variable maps

#### Phase 2: Update CI/CD
1. Modify workflows to use workspaces
2. Test workspace switching
3. Update backend configuration

#### Phase 3: Module Versioning
1. Implement module versioning strategy
2. Update module references
3. Test version rollbacks

#### Phase 4: Cleanup
1. Remove old environment directories
2. Update documentation
3. Test full workflow

### Benefits of This Approach

1. **Reduced Maintenance**: One root module instead of three
2. **Enforced Workflow**: CI/CD controls which workspace gets deployed
3. **Isolated Testing**: Module changes can be tested in dev workspace
4. **Consistent State**: Each workspace has isolated state
5. **Version Control**: Module versions can be managed independently

### Considerations

1. **Learning Curve**: Team needs to understand workspaces
2. **State Management**: Need to manage multiple workspace states
3. **Module Versioning**: Need to implement versioning strategy
4. **Migration Effort**: Significant refactoring required

### Alternative: Terraform Cloud

If you want even more control, consider Terraform Cloud:

```hcl
# environments/base/main.tf
terraform {
  cloud {
    organization = "your-org"
    workspaces {
      name = "tf-playground-${var.environment}"
    }
  }
}
```

This would give you:
- Web-based workspace management
- Built-in version control
- Team collaboration features
- Cost estimation
- Policy enforcement 