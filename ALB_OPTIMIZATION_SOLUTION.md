# ALB Optimization Solution for Dev Environment

## Problem Statement
The dev environment has an unnecessary Application Load Balancer (ALB) running, which adds ~$18/month in costs and complexity. Since we're using EKS with its own LoadBalancer service, the ALB serves no purpose.

## Current Architecture Issue

### Root Cause
The loadbalancer module is **always created** in `environments/terraform/main.tf`, regardless of whether it's needed:

```hcl
# Current: Always created
module "loadbalancer" {
  source = "../../modules/loadbalancer"
  # ... configuration
}
```

### Dependencies Analysis
The loadbalancer module is used by:
1. **ASG modules** (blue_asg, green_asg) - but disabled in dev (`enable_asg = false`)
2. **ECS module** - but disabled in dev (`enable_ecs = false`) 
3. **Logging module** - for CloudWatch ALB metrics
4. **Outputs** - for displaying ALB information

## Proposed Solution

### 1. Make LoadBalancer Module Conditional

**File**: `environments/terraform/main.tf`
**Change**: Make the loadbalancer module conditional based on actual need

```hcl
# Proposed: Only created when needed
module "loadbalancer" {
  count = (var.enable_asg || var.enable_ecs) ? 1 : 0
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
```

### 2. Update ASG Module References

**File**: `environments/terraform/main.tf`
**Change**: Update ASG modules to handle null values when loadbalancer doesn't exist

```hcl
# Blue Auto Scaling Group
module "blue_asg" {
  count  = var.enable_asg ? 1 : 0
  source = "../../modules/compute/asg"
  
  # ... other configuration ...
  alb_security_group_id = var.enable_asg ? module.loadbalancer[0].alb_security_group_id : null
  target_group_arn      = var.enable_asg ? module.loadbalancer[0].blue_target_group_arn : null
}

# Green Auto Scaling Group  
module "green_asg" {
  count  = var.enable_asg ? 1 : 0
  source = "../../modules/compute/asg"
  
  # ... other configuration ...
  alb_security_group_id = var.enable_asg ? module.loadbalancer[0].alb_security_group_id : null
  target_group_arn      = var.enable_asg ? module.loadbalancer[0].green_target_group_arn : null
}
```

### 3. Update Logging Module

**File**: `environments/terraform/main.tf`
**Change**: Update logging module to handle environments without ALB

```hcl
# Logging Module
module "logging" {
  source = "../../modules/logging"

  environment    = var.environment
  aws_region     = var.aws_region
  alb_name       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_name : null
  alb_identifier = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_identifier : null

  # Use log group names from global environment
  application_log_group_name = data.terraform_remote_state.global.outputs.application_log_groups[var.environment]
  system_log_group_name      = data.terraform_remote_state.global.outputs.system_log_groups[var.environment]
  alarm_log_group_name       = data.terraform_remote_state.global.outputs.alarm_log_groups[var.environment]
}
```

### 4. Update Outputs

**File**: `environments/terraform/outputs.tf`
**Change**: Update outputs to handle null values when ALB doesn't exist

```hcl
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_dns_name : null
}

output "alb_url" {
  description = "URL to access the application via ALB"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_url : null
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_zone_id : null
}

output "blue_target_group_arn" {
  description = "ARN of the blue target group"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].blue_target_group_arn : null
}

output "green_target_group_arn" {
  description = "ARN of the green target group"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].green_target_group_arn : null
}

output "application_url" {
  description = "URL to access the application"
  value       = (var.enable_asg || var.enable_ecs) ? module.loadbalancer[0].alb_url : "EKS environment - use Kubernetes LoadBalancer service"
}

output "health_check_url" {
  description = "URL for health checks"
  value       = (var.enable_asg || var.enable_ecs) ? "${module.loadbalancer[0].alb_url}/health" : "EKS environment - use Kubernetes LoadBalancer service"
}

output "deployment_validation_url" {
  description = "URL for deployment validation"
  value       = (var.enable_asg || var.enable_ecs) ? "${module.loadbalancer[0].alb_url}/deployment/validate" : "EKS environment - use Kubernetes LoadBalancer service"
}
```

### 5. Update ECS Integration (if needed)

**File**: `environments/terraform/ecs-integration.tf`
**Change**: Update ECS module to handle conditional loadbalancer

```hcl
# ECS Module (conditionally created)
module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "../../modules/ecs"

  # ... other configuration ...
  
  # Load Balancer Integration (uses existing ALB)
  blue_target_group_arn  = var.enable_ecs ? module.loadbalancer[0].blue_target_group_arn : null
  green_target_group_arn = var.enable_ecs ? module.loadbalancer[0].green_target_group_arn : null
}
```

## Benefits

- **Cost Savings**: ~$18/month by eliminating unnecessary ALB
- **Simplified Architecture**: EKS environments use only their own load balancer
- **Cleaner Separation**: ALB only for environments that actually need it
- **Maintained Flexibility**: ASG/ECS environments still get ALB when needed

## Architecture Result

- **EKS Environments**: Kubernetes LoadBalancer service only
- **ECS Environments**: ALB + target groups  
- **ASG Environments**: ALB + instance targets

## Testing

After implementing these changes:

1. Run `terraform plan -var-file=dev.tfvars` to verify no ALB is created
2. Verify EKS LoadBalancer service still works: `kubectl get service dev-flask-app-service`
3. Test application access via EKS ELB
4. Verify no breaking changes in staging/production environments

## Files to Modify

1. `environments/terraform/main.tf` - Make loadbalancer module conditional
2. `environments/terraform/outputs.tf` - Update outputs for null handling
3. `environments/terraform/ecs-integration.tf` - Update ECS integration (if needed)

## Current State

- ✅ EKS LoadBalancer service working: `http://a3b392faa32d94e6a9db65bc0989f997-652733936.us-east-2.elb.amazonaws.com:8080/health/simple`
- ✅ ALB shows appropriate message for EKS environments
- ❌ Unnecessary ALB still running in dev environment
- ❌ ~$18/month cost overhead 