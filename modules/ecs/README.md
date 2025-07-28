# ECS Fargate Module

This module creates a complete ECS Fargate infrastructure for containerized application deployment, designed to work alongside existing Auto Scaling Groups for gradual migration.

## 🏗️ Architecture

### Blue-Green Deployment with ECS
```
Internet → ALB → Target Group (Blue) → ECS Blue Service → Container → RDS
                    ↓
              Target Group (Green) → ECS Green Service → Container → RDS
```

### Key Components
- **ECR Repository**: Container image storage
- **ECS Cluster**: Fargate cluster with Container Insights
- **Task Definitions**: Blue and green task definitions
- **ECS Services**: Blue and green services with auto-scaling
- **IAM Roles**: Task execution and application roles
- **Security Groups**: Container networking
- **Load Balancer Integration**: Works with existing ALB

## 🚀 Features

### Container Orchestration
- **Fargate**: Serverless container execution
- **Auto-scaling**: Built-in ECS auto-scaling
- **Health Checks**: Container and application health monitoring
- **Rollback**: Automatic rollback on deployment failures

### Security
- **IAM Roles**: Least privilege access
- **Parameter Store**: Secure credential management
- **Security Groups**: Network isolation
- **Private Subnets**: Containers run in private subnets

### Monitoring
- **CloudWatch Logs**: Structured logging
- **Container Insights**: ECS-native monitoring
- **Health Checks**: Multi-level health monitoring

## 📋 Usage

### Basic Usage
```hcl
module "ecs" {
  source = "../../modules/ecs"

  environment = "staging"
  aws_region  = "us-east-2"
  
  # Network Configuration
  vpc_id            = module.networking.vpc_id
  private_subnets   = module.networking.private_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  
  # Load Balancer Integration
  blue_target_group_arn  = module.loadbalancer.blue_target_group_arn
  green_target_group_arn = module.loadbalancer.green_target_group_arn
  
  # Database Configuration
  db_host = module.database.db_instance_endpoint
  db_user = "tfplayground_user"
  db_name = "tfplayground"
  
  # Logging
  application_log_group_name = module.logging.application_log_group_name
  
  # Resource Configuration
  task_cpu    = 512
  task_memory = 1024
  
  # Service Configuration
  blue_desired_count  = 1
  green_desired_count = 0
}
```

### Advanced Configuration
```hcl
module "ecs" {
  source = "../../modules/ecs"

  environment = "production"
  aws_region  = "us-east-2"
  
  # Network
  vpc_id            = module.networking.vpc_id
  private_subnets   = module.networking.private_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  
  # Load Balancer
  blue_target_group_arn  = module.loadbalancer.blue_target_group_arn
  green_target_group_arn = module.loadbalancer.green_target_group_arn
  
  # Database
  db_host = module.database.db_instance_endpoint
  db_user = "tfplayground_user"
  db_name = "tfplayground"
  
  # Logging
  application_log_group_name = module.logging.application_log_group_name
  
  # High Performance Configuration
  task_cpu    = 1024  # 1 vCPU
  task_memory = 2048  # 2 GB
  
  # High Availability
  blue_desired_count  = 2
  green_desired_count = 0
}
```

## 🔧 Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name | `string` | n/a | yes |
| aws_region | AWS region | `string` | `"us-east-2"` | no |
| vpc_id | VPC ID | `string` | n/a | yes |
| private_subnets | Private subnet IDs | `list(string)` | n/a | yes |
| alb_security_group_id | ALB security group ID | `string` | n/a | yes |
| blue_target_group_arn | Blue target group ARN | `string` | n/a | yes |
| green_target_group_arn | Green target group ARN | `string` | n/a | yes |
| db_host | Database host | `string` | n/a | yes |
| db_user | Database username | `string` | `"tfplayground_user"` | no |
| db_name | Database name | `string` | `"tfplayground"` | no |
| application_log_group_name | CloudWatch log group name | `string` | n/a | yes |
| task_cpu | CPU units (1024 = 1 vCPU) | `number` | `512` | no |
| task_memory | Memory in MiB | `number` | `1024` | no |
| blue_desired_count | Blue service task count | `number` | `1` | no |
| green_desired_count | Green service task count | `number` | `0` | no |

## 📊 Outputs

| Name | Description |
|------|-------------|
| ecr_repository_url | ECR repository URL |
| ecs_cluster_name | ECS cluster name |
| blue_service_name | Blue ECS service name |
| green_service_name | Green ECS service name |
| container_image_url | Full container image URL |
| ecs_environment_summary | Complete environment summary |

## 🔄 Migration Strategy

### Phase 1: Parallel Deployment
- Deploy ECS alongside existing ASG
- Start with green service (0 tasks)
- Test ECS deployment independently

### Phase 2: Traffic Migration
- Scale up green service to 1 task
- Switch ALB traffic to green target group
- Monitor and validate

### Phase 3: Cleanup
- Scale down blue service to 0 tasks
- Remove ASG resources (optional)
- Complete migration

## 🚀 Deployment Commands

### Build and Push Container
```bash
# Build container image
docker build -t flask-app app/

# Tag for ECR
docker tag flask-app:latest $ECR_REPO:latest

# Push to ECR
docker push $ECR_REPO:latest
```

### Deploy Infrastructure
```bash
# Deploy ECS infrastructure
terraform apply

# Update ECS service with new image
aws ecs update-service \
  --cluster staging-ecs-cluster \
  --service staging-green-service \
  --force-new-deployment
```

## 🔒 Security Considerations

### IAM Roles
- **Task Execution Role**: Pulls images from ECR
- **Task Role**: Accesses Parameter Store and CloudWatch

### Network Security
- Containers run in private subnets
- Security groups restrict traffic to ALB only
- No direct internet access

### Credential Management
- Database password from Parameter Store
- No hardcoded secrets in task definitions
- Secure string encryption

## 📈 Monitoring

### CloudWatch Integration
- Application logs via awslogs driver
- Container Insights for ECS metrics
- Custom application metrics

### Health Checks
- Container health checks (Docker level)
- Application health checks (/health/simple)
- Load balancer health checks

## 💰 Cost Optimization

### Fargate Pricing
- Pay per vCPU and memory used
- Scale to zero when not needed
- No idle instance costs

### Resource Sizing
- Start with minimal resources (512 CPU, 1GB memory)
- Monitor usage and scale as needed
- Use auto-scaling for variable loads

## 🛠️ Troubleshooting

### Common Issues
1. **Container won't start**: Check task definition and IAM roles
2. **Can't pull image**: Verify ECR repository policy
3. **Database connection fails**: Check Parameter Store access
4. **Health checks failing**: Verify application endpoints

### Debug Commands
```bash
# Check ECS service status
aws ecs describe-services \
  --cluster staging-ecs-cluster \
  --services staging-blue-service

# View container logs
aws logs tail /aws/ecs/staging-application --follow

# Check task definition
aws ecs describe-task-definition \
  --task-definition staging-blue-task
``` 