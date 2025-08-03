# Template Quick Reference Guide

## 🚀 Rapid Deployment Patterns

### Dev Environment (Cost-Optimized)
```terraform
# dev.tfvars
enable_ecs = true
enable_eks = false
enable_asg = false
enable_private_subnets = false
blue_ecs_desired_count = 1
```

### Production EKS Environment
```terraform
# production.tfvars
enable_eks = true
enable_ecs = false
enable_asg = false
enable_private_subnets = true
node_group_desired_size = 2
```

### Blue-Green ASG Environment
```terraform
# staging.tfvars
enable_asg = true
enable_ecs = false
enable_eks = false
enable_private_subnets = true
blue_asg_desired_capacity = 2
```

## 🔧 Key Configuration Patterns

### 1. Conditional Module Creation
```terraform
module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "../../modules/ecs"
  # ... configuration
}
```

### 2. Environment-Aware Subnet Selection
```terraform
private_subnets = var.enable_private_subnets ? 
  module.networking.private_subnet_ids : 
  module.networking.public_subnet_ids
```

### 3. Conditional Public IP Assignment
```terraform
assign_public_ip = var.enable_private_subnets ? false : true
```

## 🐛 Common Issues & Solutions

### ECS Tasks Stuck in PENDING
**Problem**: Tasks can't pull Docker images from ECR
**Solution**: Set `assign_public_ip = true` for public subnets

### ALB 503 Errors
**Problem**: Load balancer has no healthy targets
**Solution**: Check ECS task status and security group rules

### Terraform State Conflicts
**Problem**: Resources exist but configuration changed
**Solution**: Use `terraform import` with original config, then `terraform destroy -target`

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] Choose compute platform (ECS/EKS/ASG)
- [ ] Configure networking (public/private subnets)
- [ ] Set environment variables in `tfvars`
- [ ] Build and push Docker image to ECR

### Deployment
- [ ] Run `terraform plan -var-file=env.tfvars`
- [ ] Apply changes with `terraform apply -var-file=env.tfvars`
- [ ] Verify service health checks
- [ ] Test application endpoints

### Post-Deployment
- [ ] Run database bootstrap script
- [ ] Verify monitoring and alerting
- [ ] Test blue-green deployment (if applicable)
- [ ] Document environment-specific configurations

## 🎯 Template Benefits

### For New Projects
1. **Clone template**
2. **Update environment variables**
3. **Deploy infrastructure**
4. **Deploy application**

### For Existing Projects
1. **Add conditional logic**
2. **Test all compute platforms**
3. **Optimize for specific use cases**
4. **Remove unnecessary conditionals**

## 📚 Documentation References

- **Migration Lessons**: `docs/eks-to-ecs-migration-lessons.md`
- **Current Status**: `docs/project-management/CURRENT_WORK.md`
- **Module Documentation**: `modules/*/README.md`

## 🔄 Future Refactoring Path

### Phase 1: Template Development ✅
- Maintain all conditionals
- Focus on versatility
- Document patterns

### Phase 2: Environment Optimization
- Create environment-specific modules
- Remove unnecessary conditionals
- Optimize performance

### Phase 3: Flattening
- Remove conditionals for specific environments
- Simplify configuration
- Optimize for production use

---

*This template provides a solid foundation for rapid infrastructure deployment with the flexibility to adapt to different client requirements.* 