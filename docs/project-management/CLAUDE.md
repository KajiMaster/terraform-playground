./ecs-database-bootstrap.sh dev
ECS Database Bootstrap for Environment: dev
==================================================

✅ Valid environment: dev
Getting environment configuration from Terraform outputs...
✅ Environment configuration:
  Cluster: dev-ecs-cluster
  Database: tfplayground_dev
  Database Host: dev-db.c38ukeqk0mqb.us-east-2.rds.amazonaws.com
  ALB URL: http://dev-alb-62232680.us-east-2.elb.amazonaws.com

Getting ECS task ARN for cluster: dev-ecs-cluster...
✅ Found ECS task: arn:aws:ecs:us-east-2:123324351829:task/dev-ecs-cluster/cf577cd014e042df809f6e8eb4da6e5f
Getting database password from Parameter Store...
✅ Retrieved database password
Creating SQL file in container...

The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.


An error occurred (TargetNotConnectedException) when calling the ExecuteCommand operation: The execute command failed due to an internal error. Try again later.
❌ Error: Failed to create SQL file in container
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a comprehensive Terraform project showcasing enterprise-grade Infrastructure-as-Code with multi-environment support (dev/staging/production), GitFlow CI/CD workflow, and blue-green deployment patterns. The project includes both Terraform infrastructure and a FastAPI Python application for demonstration.

## Key Architecture

### Multi-Environment Structure
- **Global resources**: `/environments/global/` - Shared OIDC providers, state backend, centralized secrets
- **Universal environment**: `/environments/terraform/` - Single codebase for all environments using separate state files
- **Modular design**: `/modules/` - Reusable Terraform modules for networking, compute, database, etc.
- **Application**: `/app/` - FastAPI application with Docker containerization

### State Management
- Backend: S3 bucket `tf-playground-state-vexus` 
- Staging state: `workspaces/terraform-staging.tfstate`
- Production state: `workspaces/terraform-production.tfstate`
- Global state: `global/terraform.tfstate`

## Common Commands

### Terraform Operations
```bash
# Universal environment deployment (recommended approach)
cd environments/terraform
terraform init -reconfigure
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars

# Switch to production
terraform plan -var-file=production.tfvars
terraform apply -var-file=production.tfvars

# Workspace management
terraform workspace list
terraform workspace select <workspace-name>

# Standard validation
terraform validate
terraform fmt -check
```

### Application Testing
```bash
# Local containerized testing
cd app/
./test-local.sh

# Docker operations
docker compose build
docker compose up -d
docker compose down -v
```

### Infrastructure Scripts
```bash
# Blue-green deployment testing
./scripts/blue-green-failover-test.sh
./scripts/test-health-checks.sh

# Container deployment
./scripts/build-and-deploy-container.sh [environment] [region] [tag]

# Database operations
./scripts/connect-production-db.sh
./scripts/prime-database-ecs.sh
```

## Module Architecture

### Core Infrastructure Modules
- `networking/` - VPC, subnets, NAT gateways with cost optimization
- `compute/asg/` - Auto Scaling Groups for blue-green deployments  
- `loadbalancer/` - ALB with target groups and health checks
- `database/` - RDS instances with automated bootstrapping
- `ecs/` - ECS Fargate services for containerized applications

### Supporting Modules
- `secrets/` - Centralized AWS Secrets Manager integration (67% cost reduction)
- `ssh-keys/` - Shared SSH key management across environments
- `ssm/` - Systems Manager for automated database initialization
- `oidc/` - GitHub Actions OIDC provider for secure CI/CD

## Blue-Green Deployment Pattern

The infrastructure supports zero-downtime deployments using blue-green patterns:
- Each environment has `blue_asg` and `green_asg` auto scaling groups
- Load balancer switches traffic between active/inactive groups
- Health checks validate deployment before traffic switching
- Automated rollback capabilities

## Environment Variables and Configuration

### Environment-Specific Files
- `staging.tfvars` - Staging environment configuration
- `production.tfvars` - Production environment configuration  
- `dev.tfvars` - Development environment configuration
- `lab-minimal.tfvars` - Minimal lab environment

### Key Variables
- `environment` - Environment name (dev/staging/production)
- `aws_region` - AWS region (default: us-east-2)
- `vpc_cidr` - VPC CIDR block
- `blue_desired_capacity`, `green_desired_capacity` - ASG scaling
- `webserver_instance_type`, `db_instance_type` - Instance sizing

## CI/CD Integration

### GitHub Actions Workflows
- **Staging**: `.github/workflows/staging-terraform.yml` - Triggers on develop branch
- **Production**: `.github/workflows/production-terraform.yml` - Triggers on main branch
- Path-based triggers exclude global-only modules and documentation

### Workflow Features
- Terraform version pinned to 1.12.0
- OIDC authentication (no stored AWS credentials)
- Container building and deployment
- Blue-green deployment automation
- Manual workflow dispatch with options

## Cost Optimization Features

### Centralized Secrets Strategy
- Single shared secrets in `/tf-playground/all/` path
- Reduces Secrets Manager costs by 67% ($1.60/month savings)
- Shared SSH keys across environments

### Instance Sizing
- Default to t3.micro and db.t3.micro for cost efficiency
- Configurable via terraform.tfvars for each environment
- Auto-scaling minimums set to 1 for cost control

## Application Structure

### FastAPI Application (`/app/`)
- **Dependencies**: requirements.txt with FastAPI, SQLAlchemy, Celery, AWS SDK
- **Health checks**: `/health`, `/health/simple` endpoints
- **Database**: MySQL with automated schema setup
- **Containerization**: Docker with docker-compose.yml
- **Testing**: Comprehensive endpoint testing in test-local.sh

### Key Endpoints
- `/` - Main application with deployment color and contact data
- `/health` - Enhanced health check with database connectivity
- `/info` - Container and environment information
- `/error/500`, `/error/slow` - Chaos testing endpoints

## Testing and Validation

### Infrastructure Testing
```bash
# Validate all Terraform configurations
find . -name "*.tf" -execdir terraform validate \;

# Check formatting
terraform fmt -check -recursive

# Security scanning (if tfsec installed)
tfsec .
```

### Application Testing
```bash
# Full local stack test
cd app && ./test-local.sh

# Parameter store connectivity test  
cd app && ./test-parameter-store.sh
```

## Documentation

Extensive documentation available in `/docs/`:
- `blue-green-deployment-project.md` - Zero-downtime deployment implementation
- `database-bootstrap.md` - Automated database setup
- `centralized-secrets-refactor.md` - Cost optimization strategies
- `project-direction-and-lessons.md` - Strategic decisions and lessons learned

## Security Considerations

- OIDC authentication eliminates stored AWS credentials
- Least privilege IAM roles for all services
- Centralized secrets management with encryption
- Network isolation with private subnets for databases
- Security groups with minimal required access

## Project Management & Coordination

### Current Sprint/Focus
**Status**: EKS LoadBalancer Implementation Complete
**Last Updated**: 2025-08-03

**Active Work**:
- ✅ EKS + LoadBalancer service working (Flask app accessible via ELB)
- Next: GitHub Actions EKS permissions integration
- Future: ALB controller implementation for advanced features

### Tool Coordination Strategy

#### Claude Code (Project Manager Role)
- Maintains project state and context
- Tracks overall progress and priorities
- Breaks down complex tasks into manageable chunks
- Updates documentation and coordination files
- Monitors blockers and technical debt

#### Cursor (Senior Developer Role)
- Deep code editing and implementation
- IDE-integrated debugging and testing
- File navigation and refactoring
- Real-time syntax checking and completion

#### Coordination Files
- `CLAUDE.md` - Overall project guidance and current sprint status
- `CURRENT_WORK.md` - Day-to-day task coordination and handoffs
- GitHub Issues - Feature tracking and larger initiatives
- Commit messages and PR descriptions for progress tracking

### Handoff Patterns
When starting new Cursor sessions:
1. Check `CURRENT_WORK.md` for active tasks
2. Review recent commits and current branch status
3. Reference current sprint focus in this file
4. Update progress before ending sessions

### Project State Tracking
- **Infrastructure**: Multi-environment Terraform with blue-green deployments
- **Application**: FastAPI with comprehensive health checks
- **CI/CD**: GitHub Actions with OIDC and automated deployments
- **Cost Optimization**: Centralized secrets and efficient instance sizing