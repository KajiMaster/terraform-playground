# Staging Environment

## 🎯 Overview

This is the staging environment for the Terraform Playground project. It uses ECS Fargate for containerized deployments with blue-green deployment capabilities.

## 🚀 Quick Start

### Database Bootstrap

To bootstrap the RDS database with sample data:

```bash
cd environments/staging
./ecs-database-bootstrap-oneliner.sh
```

This script will:
1. Find the running ECS task
2. Create the `contacts` table if it doesn't exist
3. Insert 5 sample contacts
4. Verify the data was inserted correctly

### Application Access

- **ALB URL**: http://staging-alb-1997691628.us-east-2.elb.amazonaws.com/
- **Health Check**: http://staging-alb-1997691628.us-east-2.elb.amazonaws.com/health

## 🔧 Configuration

### Environment Variables

- **Environment**: `staging`
- **AWS Region**: `us-east-2`
- **ECS Enabled**: `true`
- **Database**: RDS MySQL in private subnet
- **Load Balancer**: ALB with blue-green target groups

### Resource Sizing (Cost Optimized)

- **ECS Task**: 0.5 vCPU, 1GB RAM
- **RDS**: db.t3.micro
- **EC2**: t3.micro (if ASG enabled)

## 📋 Database Schema

The application uses a `contacts` table with the following structure:

```sql
CREATE TABLE contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🔍 Troubleshooting

### Common Issues

1. **No ECS tasks found**
   - Verify ECS service is running: `aws ecs describe-services --cluster staging-ecs-cluster --services staging-blue-service`
   - Check service health and desired count

2. **Database connection failures**
   - Verify RDS instance is available
   - Check security group rules allow traffic from ECS tasks

3. **ECS Exec failures**
   - Ensure ECS Exec is enabled on the task definition
   - Check IAM permissions for ECS Exec
   - Verify the container has MySQL client tools installed

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster staging-ecs-cluster --services staging-blue-service

# List ECS tasks
aws ecs list-tasks --cluster staging-ecs-cluster

# Check application logs
aws logs tail /aws/ecs/staging-application --follow

# Force new deployment
aws ecs update-service --cluster staging-ecs-cluster --service staging-blue-service --force-new-deployment
```

## 📚 Related Documentation

- [Database Bootstrap Documentation](../../docs/database-bootstrap.md)
- [Blue-Green Deployment Project](../../docs/blue-green-deployment-project.md)
- [ECS Module Documentation](../../modules/ecs/README.md) 