# EKS to ECS Migration: Lessons Learned & Template Architecture

## Overview
Successfully migrated the dev environment from EKS back to ECS while maintaining a versatile, conditional architecture that can serve as a boilerplate template for future projects.

## Key Breakthrough: ECS Public IP Assignment

### The Problem
ECS tasks were stuck in `PENDING` status with the error:
```
LastStatus: PENDING
DesiredStatus: RUNNING
```

### Root Cause
ECS tasks in public subnets with `assign_public_ip = false` cannot access the internet to pull Docker images from ECR.

### The Solution
**Standard AWS ECS Network Configuration Pattern:**

```terraform
network_configuration {
  security_groups  = [aws_security_group.ecs_tasks.id]
  subnets          = var.private_subnets
  assign_public_ip = var.enable_private_subnets ? false : true
}
```

### Why This Matters
- **Public subnets + `assign_public_ip = true`**: Tasks can access internet (pull Docker images)
- **Private subnets + `assign_public_ip = false`**: Tasks route through NAT Gateway

## Conditional Architecture Pattern

### 1. Environment-Aware Subnet Selection
```terraform
# environments/terraform/ecs-integration.tf
private_subnets = var.enable_private_subnets ? 
  module.networking.private_subnet_ids : 
  module.networking.public_subnet_ids
```

### 2. Conditional Public IP Assignment
```terraform
# modules/ecs/main.tf
assign_public_ip = var.enable_private_subnets ? false : true
```

### 3. Conditional Load Balancer Configuration
```terraform
# modules/loadbalancer/main.tf
count = var.enable_eks ? 0 : 1  # Don't create ALB for EKS
```

## Template Architecture Benefits

### 1. **Versatility**
- Single codebase supports EKS, ECS, and ASG
- Environment-specific configurations via `tfvars`
- Easy switching between compute platforms

### 2. **Reusability**
- Drop-in template for new client projects
- Conditional logic handles different requirements
- Standardized patterns across environments

### 3. **Maintainability**
- Clear separation of concerns
- Environment-specific variables
- Consistent naming conventions

## Migration Process

### 1. **State Management Best Practices**
✅ **DO**: Use `terraform import` to bring resources back into state
❌ **DON'T**: Use `terraform state rm` (leads to orphaned resources)

### 2. **Resource Transition Pattern**
```bash
# 1. Import resources with original configuration
terraform import -var-file=working_eks_dev.tfvars kubernetes_deployment.flask_app default/flask-app

# 2. Destroy old resources with original config
terraform destroy -target=kubernetes_deployment.flask_app -var-file=working_eks_dev.tfvars

# 3. Apply new configuration
terraform apply -var-file=dev.tfvars
```

### 3. **Docker Image Management**
```bash
# Build and tag for environment
docker tag flask-app:latest $ECR_REPO:dev-latest
docker push $ECR_REPO:dev-latest
```

## Template Structure

### Core Variables
```terraform
# environments/terraform/dev.tfvars
enable_ecs = true
enable_eks = false
enable_asg = false
enable_private_subnets = false  # Dev pattern: public subnets only
```

### Conditional Module Creation
```terraform
# environments/terraform/main.tf
module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "../../modules/ecs"
  # ... configuration
}

module "eks" {
  count  = var.enable_eks ? 1 : 0
  source = "../../modules/eks"
  # ... configuration
}
```

### Environment-Specific Patterns

#### Dev Environment (Cost-Optimized)
- Public subnets only
- No NAT Gateway
- ECS with public IP assignment
- Minimal resource allocation

#### Staging Environment (Production-Like)
- Private subnets with NAT Gateway
- ECS with private IP assignment
- Blue-green deployment ready

#### Production Environment (High Availability)
- Multi-AZ private subnets
- EKS with LoadBalancer service
- Full monitoring and alerting

## Future Refactoring Strategy

### Phase 1: Template Development (Current)
- Maintain all conditionals
- Focus on versatility and reusability
- Document all patterns

### Phase 2: Environment-Specific Optimization
- Create environment-specific modules
- Remove unnecessary conditionals
- Optimize for specific use cases

### Phase 3: Flattening (Future)
- Remove conditionals for specific environments
- Simplify configuration
- Optimize performance

## Key Learning Points

### 1. **AWS ECS Network Requirements**
- `awsvpc` mode requires explicit subnet and security group configuration
- Public IP assignment is critical for internet access
- NAT Gateway required for private subnets

### 2. **Terraform State Management**
- Never use `terraform state rm` in production
- Always use `terraform import` for resource transitions
- Maintain backup configurations for rollback

### 3. **Conditional Architecture**
- Use `count` for conditional module creation
- Pass environment variables to modules
- Handle null references gracefully

### 4. **Docker Image Strategy**
- Environment-specific tags (`dev-latest`, `staging-latest`)
- ECR authentication required for pushes
- Health checks in Docker images

## Template Usage Guide

### For New Client Projects

1. **Clone the template**
2. **Update environment variables**
3. **Choose compute platform** (ECS/EKS/ASG)
4. **Configure networking** (public/private subnets)
5. **Deploy and test**

### Environment Configuration Examples

#### Quick Dev Setup
```terraform
enable_ecs = true
enable_private_subnets = false
blue_ecs_desired_count = 1
```

#### Production EKS Setup
```terraform
enable_eks = true
enable_private_subnets = true
node_group_desired_size = 2
```

#### Blue-Green ASG Setup
```terraform
enable_asg = true
enable_private_subnets = true
blue_asg_desired_capacity = 2
```

## Success Metrics

✅ **Dev Environment**: ECS running with public subnets  
✅ **Application**: Flask app responding on ALB  
✅ **Database**: RDS connected and populated  
✅ **Monitoring**: CloudWatch dashboards active  
✅ **Security**: IAM roles and security groups configured  

## Next Steps

1. **Documentation**: Add to project management docs
2. **Testing**: Validate all conditional paths
3. **Optimization**: Performance tuning for specific environments
4. **Automation**: CI/CD pipeline for template deployment

---

*This template provides a solid foundation for rapid infrastructure deployment with the flexibility to adapt to different client requirements while maintaining best practices and cost optimization.* 