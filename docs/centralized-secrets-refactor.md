# Centralized Secrets Refactor

## Problem Statement

**Current Issue**: Each environment creates its own secrets in AWS Secrets Manager
- **Cost Impact**: Multiple secrets = higher AWS costs
- **Complexity**: Managing secrets across environments
- **Redundancy**: Same SSH keys and database patterns repeated

**Solution**: Centralized key management with environment-specific suffixes

## Refactor Strategy

### Option 1: Single SSH Key Pair (Recommended)

#### Current (Expensive)
```
AWS Secrets Manager:
├── /tf-playground/dev/ssh-key
├── /tf-playground/dev/ssh-key-public  
├── /tf-playground/staging/ssh-key
├── /tf-playground/staging/ssh-key-public
├── /tf-playground/production/ssh-key
└── /tf-playground/production/ssh-key-public
```

#### Final Implementation (Cost Optimized)
```
AWS Secrets Manager:
├── /tf-playground/all/ssh-key (single private key)
├── /tf-playground/all/ssh-key-public (single public key)
└── /tf-playground/all/db-pword (single database password)

AWS Key Pairs:
├── tf-playground-dev-key
├── tf-playground-staging-key  
└── tf-playground-production-key
```

### Option 2: Environment-Specific Database Credentials

#### Current (Expensive)
```
AWS Secrets Manager:
├── /tf-playground/dev/database/credentials-abc123
├── /tf-playground/staging/database/credentials-def456
└── /tf-playground/production/database/credentials-ghi789
```

#### Proposed (Cost Optimized)
```
AWS Secrets Manager:
└── /tf-playground/database/credentials (single secret)

Database Users:
├── tfplayground_dev_user
├── tfplayground_staging_user
└── tfplayground_production_user
```

## Implementation Plan

### Phase 1: Create Centralized SSH Key Management

#### 1. Create Global SSH Key Module

```hcl
# modules/ssh-keys/main.tf
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_secretsmanager_secret" "ssh_private" {
  name        = "/tf-playground/ssh-key"
  description = "Centralized SSH private key for all environments"
}

resource "aws_secretsmanager_secret_version" "ssh_private" {
  secret_id     = aws_secretsmanager_secret.ssh_private.id
  secret_string = tls_private_key.main.private_key_pem
}

resource "aws_secretsmanager_secret" "ssh_public" {
  name        = "/tf-playground/ssh-key-public"
  description = "Centralized SSH public key for all environments"
}

resource "aws_secretsmanager_secret_version" "ssh_public" {
  secret_id     = aws_secretsmanager_secret.ssh_public.id
  secret_string = tls_private_key.main.public_key_openssh
}

# Environment-specific key pairs using the same key
resource "aws_key_pair" "environment_key" {
  key_name   = "tf-playground-${var.environment}-key"
  public_key = tls_private_key.main.public_key_openssh

  tags = {
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}
```

#### 2. Update Environment Configurations

```hcl
# environments/staging/main.tf
module "ssh_keys" {
  source      = "../../modules/ssh-keys"
  environment = var.environment
}

# Use the centralized key
module "blue_asg" {
  # ... other configuration
  key_name = module.ssh_keys.key_name
}
```

### Phase 2: Centralized Database Credentials

#### 1. Create Global Database Module

```hcl
# modules/database-global/main.tf
resource "aws_secretsmanager_secret" "database_credentials" {
  name        = "/tf-playground/database/credentials"
  description = "Centralized database credentials for all environments"
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({
    username = "tfplayground_user"
    password = random_password.db_password.result
  })
}

resource "random_password" "db_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Environment-specific database users
resource "aws_db_instance" "environment_db" {
  # ... database configuration
  username = "tfplayground_${var.environment}_user"
  password = random_password.db_password.result
}
```

### Phase 3: Update Secrets Module

#### 1. Simplify Secrets Module

```hcl
# modules/secrets/main.tf (simplified)
# Remove SSH key management - handled by ssh-keys module
# Remove database credentials - handled by database-global module

# Only keep environment-specific random suffixes for resource naming
resource "random_id" "resource_suffix" {
  byte_length = 4
}

output "resource_suffix" {
  value = random_id.resource_suffix.hex
}
```

## Cost Savings Analysis

### Current Costs (Monthly)
- **6 Secrets** × $0.40 = $2.40
- **3 Key Pairs** = $0.00 (free)
- **Total**: $2.40/month

### Proposed Costs (Monthly)
- **2 Secrets** × $0.40 = $0.80
- **3 Key Pairs** = $0.00 (free)
- **Total**: $0.80/month

### **Savings**: $1.60/month (67% reduction)

## Migration Strategy

### Step 1: Create Global Resources
1. Create `modules/ssh-keys/` module
2. Create `modules/database-global/` module
3. Deploy global resources first

### Step 2: Update Environment Configurations
1. Update staging environment to use centralized keys
2. Update production environment to use centralized keys
3. Update dev environment to use centralized keys

### Step 3: Cleanup Old Secrets
1. Remove old environment-specific secrets
2. Update documentation
3. Verify all environments work with centralized approach

## Benefits

### 1. **Cost Reduction**
- 67% reduction in Secrets Manager costs
- Fewer AWS resources to manage

### 2. **Simplified Management**
- Single source of truth for SSH keys
- Centralized database credentials
- Easier to rotate keys

### 3. **Better Security**
- Consistent key management across environments
- Easier to audit and monitor
- Reduced attack surface

### 4. **Demonstration Value**
- Shows understanding of cost optimization
- Demonstrates centralized resource management
- Real-world enterprise patterns

## Implementation Steps

### Immediate Actions
1. **Create centralized SSH key module**
2. **Update staging environment first** (test environment)
3. **Verify functionality**
4. **Update production environment**
5. **Clean up old secrets**

### Long-term Benefits
- **Portfolio enhancement**: Shows cost-conscious infrastructure design
- **Real-world skills**: Centralized key management is common in enterprises
- **Maintenance reduction**: Fewer secrets to manage and rotate

## Risk Mitigation

### 1. **Backup Strategy**
- Export existing secrets before migration
- Keep old secrets until migration is complete
- Test rollback procedures

### 2. **Gradual Migration**
- Migrate one environment at a time
- Test thoroughly between migrations
- Keep old and new systems running in parallel

### 3. **Documentation**
- Update all documentation
- Create migration runbooks
- Document new centralized approach

This refactor will significantly reduce costs while improving the architecture and demonstrating enterprise-grade resource management skills. 