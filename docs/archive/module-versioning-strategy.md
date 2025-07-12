# Module Versioning Strategy

## Current Problem

All environments use the same local module source:
```hcl
module "networking" {
  source = "../../modules/networking"  # Always latest version
  # ... variables
}
```

This means:
- Module changes affect all environments immediately
- No way to test module changes safely
- No rollback capability for module versions
- Risk of breaking production with experimental changes

## Solution: Git-Based Module Versioning

### Step 1: Create Separate Module Repositories

```bash
# Create separate repositories for each module
git clone https://github.com/your-org/terraform-module-networking.git
git clone https://github.com/your-org/terraform-module-compute.git
git clone https://github.com/your-org/terraform-module-database.git
git clone https://github.com/your-org/terraform-module-secrets.git
git clone https://github.com/your-org/terraform-module-ssm.git
git clone https://github.com/your-org/terraform-module-oidc.git
```

### Step 2: Version Your Modules

```bash
# In each module repository
cd terraform-module-networking

# Create version tags
git tag v1.0.0
git tag v1.1.0
git tag v1.2.0
git push --tags
```

### Step 3: Update Module References

```hcl
# environments/staging/main.tf
module "networking" {
  source = "git::https://github.com/your-org/terraform-module-networking.git?ref=v1.2.0"
  
  environment   = var.environment
  vpc_cidr      = var.vpc_cidr
  public_cidrs  = var.public_subnet_cidrs
  private_cidrs = var.private_subnet_cidrs
  azs           = var.availability_zones
}

module "compute" {
  source = "git::https://github.com/your-org/terraform-module-compute.git?ref=v1.1.0"
  
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  # ... other variables
}
```

### Step 4: Environment-Specific Module Versions

```hcl
# environments/dev/main.tf (latest versions for testing)
module "networking" {
  source = "git::https://github.com/your-org/terraform-module-networking.git?ref=v1.3.0-beta"
  # ... variables
}

# environments/staging/main.tf (stable versions)
module "networking" {
  source = "git::https://github.com/your-org/terraform-module-networking.git?ref=v1.2.0"
  # ... variables
}

# environments/production/main.tf (proven versions)
module "networking" {
  source = "git::https://github.com/your-org/terraform-module-networking.git?ref=v1.1.0"
  # ... variables
}
```

## Module Development Workflow

### 1. Development Phase

```bash
# In module repository
git checkout -b feature/new-feature
# Make changes
git commit -m "Add new feature"
git push origin feature/new-feature

# Test in dev environment
cd terraform-playground/environments/dev
# Update module source to use branch
terraform apply -var='networking_module_source=git::https://github.com/your-org/terraform-module-networking.git?ref=feature/new-feature'
```

### 2. Testing Phase

```bash
# Create beta version
git tag v1.3.0-beta
git push --tags

# Test in staging
cd terraform-playground/environments/staging
# Update to beta version
terraform apply -var='networking_module_source=git::https://github.com/your-org/terraform-module-networking.git?ref=v1.3.0-beta'
```

### 3. Release Phase

```bash
# Create stable version
git tag v1.3.0
git push --tags

# Promote to staging
cd terraform-playground/environments/staging
terraform apply -var='networking_module_source=git::https://github.com/your-org/terraform-module-networking.git?ref=v1.3.0'
```

### 4. Production Phase

```bash
# After staging validation, promote to production
cd terraform-playground/environments/production
terraform apply -var='networking_module_source=git::https://github.com/your-org/terraform-module-networking.git?ref=v1.3.0'
```

## Version Management Strategy

### Semantic Versioning

```bash
# Major.Minor.Patch
v1.2.3
# 1 = Major (breaking changes)
# 2 = Minor (new features, backward compatible)
# 3 = Patch (bug fixes)
```

### Environment Promotion Strategy

```
Development: v1.3.0-beta (latest features)
Staging:     v1.2.0 (stable, tested)
Production:  v1.1.0 (proven, conservative)
```

### Rollback Strategy

```bash
# If production breaks, rollback to previous version
cd terraform-playground/environments/production
terraform apply -var='networking_module_source=git::https://github.com/your-org/terraform-module-networking.git?ref=v1.0.0'
```

## Implementation Steps

### Phase 1: Module Extraction

1. **Extract Current Modules**
   ```bash
   # Create separate repositories for each module
   mkdir terraform-module-networking
   cp -r modules/networking/* terraform-module-networking/
   cd terraform-module-networking
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/your-org/terraform-module-networking.git
   git push -u origin main
   ```

2. **Version the Modules**
   ```bash
   git tag v1.0.0
   git push --tags
   ```

### Phase 2: Update References

1. **Update Environment Configurations**
   ```hcl
   # Replace local module references with Git references
   module "networking" {
     source = "git::https://github.com/your-org/terraform-module-networking.git?ref=v1.0.0"
     # ... variables
   }
   ```

2. **Test Each Environment**
   ```bash
   cd environments/dev
   terraform init -upgrade
   terraform plan
   terraform apply
   ```

### Phase 3: CI/CD Integration

1. **Update Workflows**
   ```yaml
   # .github/workflows/staging-terraform.yml
   - name: Terraform Init
     run: terraform init -upgrade
   ```

2. **Add Module Version Variables**
   ```hcl
   # environments/staging/variables.tf
   variable "networking_module_version" {
     description = "Networking module version"
     type        = string
     default     = "v1.0.0"
   }
   ```

## Benefits

1. **Safe Testing**: Module changes can be tested in isolation
2. **Version Control**: Clear version history and rollback capability
3. **Environment Isolation**: Different environments can use different versions
4. **Team Collaboration**: Multiple developers can work on modules independently
5. **Release Management**: Structured promotion from dev → staging → production

## Considerations

1. **Repository Management**: Need to manage multiple module repositories
2. **Version Coordination**: Need to coordinate versions across modules
3. **Testing Overhead**: More complex testing with multiple repositories
4. **Learning Curve**: Team needs to understand Git-based module versioning

## Alternative: Terraform Registry

For even better versioning, consider publishing modules to Terraform Registry:

```hcl
module "networking" {
  source  = "your-org/networking/aws"
  version = "~> 1.2"
  
  environment = var.environment
  # ... variables
}
```

This provides:
- Built-in versioning
- Dependency resolution
- Public/private registry options
- Better documentation 