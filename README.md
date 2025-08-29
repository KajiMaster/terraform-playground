# Terraform Playground - Enterprise Infrastructure as Code

A comprehensive Terraform project demonstrating enterprise-grade Infrastructure-as-Code, CI/CD automation, and blue-green deployment patterns for career advancement.

## 🎯 Project Overview

This project showcases advanced Terraform patterns and AWS infrastructure management, designed to demonstrate real-world enterprise skills including:

- **Multi-environment Infrastructure** (dev, staging, production)
- **Multi-pattern Deployment Support** (ASG, ECS, EKS) with conditional resource creation
- **GitFlow CI/CD Workflow** with automated deployments
- **Blue-Green Deployment** patterns with zero-downtime updates
- **Cost-Optimized Architecture** with environment-specific resource patterns
- **Modular Terraform Architecture** with reusable components
- **SSM Session Manager** for keyless EC2 access
- **Automated Database Bootstrapping** via AWS SSM
- **Security Best Practices** with IAM roles and OIDC

## 🏗️ Architecture

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           AWS Infrastructure                                    │
├─────────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐              │
│  │   Dev Environment│  │Staging Environment│  │Production Env    │              │
│  │                  │  │                  │  │                  │              │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────────┐ │              │
│  │ │ VPC + Subnets│ │  │ │ VPC + Subnets│ │  │ │ VPC + Subnets│ │              │
│  │ │• Public Only │ │  │ │• Public+Private│ │  │ │• Public+Private│ │              │
│  │ │• No NAT GW   │ │  │ │• NAT Gateway │ │  │ │• NAT Gateway │ │              │
│  │ └──────────────┘ │  │ └──────────────┘ │  │ └──────────────┘ │              │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────────┐ │              │
│  │ │   ALB + WAF  │ │  │ │   ALB + WAF  │ │  │ │   ALB + WAF  │ │              │
│  │ │• Blue/Green  │ │  │ │• Blue/Green  │ │  │ │• Blue/Green  │ │              │
│  │ │  Target Groups│ │  │ │  Target Groups│ │  │ │  Target Groups│ │              │
│  │ └──────────────┘ │  │ └──────────────┘ │  │ └──────────────┘ │              │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────────┐ │              │
│  │ │Multi-Platform│ │  │ │Multi-Platform│ │  │ │Multi-Platform│ │              │
│  │ │ Compute:     │ │  │ │ Compute:     │ │  │ │ Compute:     │ │              │
│  │ │• ASG (EC2)   │ │  │ │• ASG (EC2)   │ │  │ │• ASG (EC2)   │ │              │
│  │ │• ECS (Fargate)│ │  │ │• ECS (Fargate)│ │  │ │• ECS (Fargate)│ │              │
│  │ │• EKS (K8s)   │ │  │ │• EKS (K8s)   │ │  │ │• EKS (K8s)   │ │              │
│  │ └──────────────┘ │  │ └──────────────┘ │  │ └──────────────┘ │              │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────────┐ │              │
│  │ │    RDS       │ │  │ │    RDS       │ │  │ │    RDS       │ │              │
│  │ │   MySQL 8.0  │ │  │ │   MySQL 8.0  │ │  │ │   MySQL 8.0  │ │              │
│  │ └──────────────┘ │  │ └──────────────┘ │  │ └──────────────┘ │              │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────────┐ │              │
│  │ │ CloudWatch   │ │  │ │ CloudWatch   │ │  │ │ CloudWatch   │ │              │
│  │ │• Logs+Alarms │ │  │ │• Logs+Alarms │ │  │ │• Logs+Alarms │ │              │
│  │ │• Dashboards  │ │  │ │• Dashboards  │ │  │ │• Dashboards  │ │              │
│  │ └──────────────┘ │  │ └──────────────┘ │  │ └──────────────┘ │              │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘              │
├─────────────────────────────────────────────────────────────────────────────────┤
│                        Centralized Resources                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │ • Parameter Store (DB Passwords only - SecureString)                       │ │
│  │ • ECR Registry (Shared Container Images)                                   │ │
│  │ • OIDC Provider (GitHub Actions CI/CD)                                     │ │
│  │ • S3 Backend + DynamoDB State Locking                                      │ │
│  │ • IAM Roles (Cross-service permissions)                                    │ │
│  │ • SSM Session Manager (Keyless EC2 access)                                 │ │
│  │ • SSM Automation (Database bootstrap)                                      │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
```


## 🚀 Features

### 1. Multi-Environment Support
- **Development**: Rapid iteration and testing
- **Staging**: Pre-production validation
- **Production**: Live environment with blue-green deployment

### 2. GitFlow CI/CD Workflow
```
Feature Branch → Develop → Staging → Production
     ↓              ↓         ↓         ↓
   Local Dev    Auto Deploy  Manual   Manual
   Testing      to Dev       Promote  Promote
```

### 3. Blue-Green Deployment
- **Zero-downtime deployments**
- **Automatic rollback capability**
- **Traffic switching between environments**
- **Health checks and validation**

### 4. Modular Architecture
```
modules/
├── networking/          # VPC, subnets, security groups
├── loadbalancer/        # ALB, target groups, listeners
├── compute/asg/         # Auto Scaling Groups
├── database/            # RDS instances
├── secrets/             # Parameter Store integration
├── ssm/                 # Systems Manager automation & Session Manager
└── oidc/                # GitHub Actions OIDC
```

### 5. Security Features
- **IAM roles with least privilege**
- **OIDC authentication for GitHub Actions**
- **Encrypted secrets storage**
- **Network security groups**
- **SSL/TLS termination**

## 🎛️ Deployment Patterns

The infrastructure supports **three deployment patterns** with environment-specific optimizations:

| Pattern | Use Case | Cost | Complexity |
|---------|----------|------|------------|
| **ASG** | Traditional EC2 | Medium | Low |
| **ECS** | Containerized apps | Medium | Medium |
| **EKS** | Kubernetes workloads | Low* | High |

*EKS dev environments eliminate ALB costs (~$18/month savings)

### Platform-Specific Deployment
Select the appropriate configuration file based on your platform choice:

```bash
# ECS Deployment (Containerized Applications)
terraform apply -var-file=working_ecs_dev.tfvars
terraform apply -var-file=working_ecs_staging.tfvars
terraform apply -var-file=working_ecs_production.tfvars

# EKS Deployment (Kubernetes Workloads)
terraform apply -var-file=working_eks_dev.tfvars
terraform apply -var-file=working_eks_staging.tfvars
terraform apply -var-file=working_eks_production.tfvars
```

### Pattern Selection
```hcl
# ECS Configuration (Cost-Balanced)
platform = "ecs"
enable_ecs = true
enable_eks = false
enable_asg = false
enable_private_subnets = true   # Full network isolation

# EKS Configuration (Development Cost-Optimized)
platform = "eks"
enable_ecs = false
enable_eks = true
enable_asg = false
enable_private_subnets = false  # Saves NAT gateway costs
```

📖 **Detailed Implementation**: [EKS Implementation Project](docs/eks-implementation-project.md)

## 📁 Project Structure

```
terraform-playground/
├── environments/
│   ├── global/           # Global resources (OIDC, secrets)
│   └── terraform/        # Unified infrastructure with workspace separation
│       ├── backend.tf    # Universal S3 backend configuration
│       ├── main.tf       # Main infrastructure definition
│       ├── working_ecs_dev.tfvars      # ECS development configuration
│       ├── working_ecs_staging.tfvars  # ECS staging configuration
│       ├── working_ecs_production.tfvars # ECS production configuration
│       ├── working_eks_dev.tfvars      # EKS development configuration
│       ├── working_eks_staging.tfvars  # EKS staging configuration
│       └── working_eks_production.tfvars # EKS production configuration
├── modules/
│   ├── networking/       # Network infrastructure
│   ├── loadbalancer/     # Load balancer configuration
│   ├── compute/          # Compute resources (ASG, ECS, EKS)
│   ├── database/         # Database resources
│   ├── secrets/          # Parameter Store secrets
│   ├── ssm/              # Systems Manager & Session Manager
│   └── oidc/             # OIDC provider
├── .github/
│   └── workflows/        # GitHub Actions CI/CD
├── docs/                 # Documentation
└── scripts/              # Utility scripts
```

## 🛠️ Prerequisites

- **Terraform** >= 1.0.0
- **AWS CLI** configured with appropriate permissions
- **GitHub repository** with GitHub Actions enabled
- **AWS Account** with necessary services enabled

## 🚀 Quick Start

### 1. Clone and Setup
   ```bash
git clone https://github.com/KajiMaster/terraform-playground.git
cd terraform-playground
   ```

### 2. Configure AWS
   ```bash
aws configure
# Enter your AWS access key, secret key, and region
```

### 3. Deploy Global Resources
   ```bash
cd environments/global
terraform init
terraform plan
terraform apply
   ```

### 4. Deploy Development Environment
   ```bash
cd ../terraform
terraform init

# Create and select development workspace
terraform workspace new dev
terraform workspace select dev

# Deploy with ECS platform (recommended for development)
terraform plan -var-file=working_ecs_dev.tfvars
terraform apply -var-file=working_ecs_dev.tfvars

# Or deploy with EKS platform (for Kubernetes testing)
# terraform plan -var-file=working_eks_dev.tfvars
# terraform apply -var-file=working_eks_dev.tfvars
   ```

### 5. Access the Application
   ```bash
terraform output application_url
```

## 🔄 CI/CD Workflow

### Universal Backend Architecture
All environments use a single backend configuration with workspace-based separation:

```hcl
# environments/terraform/backend.tf
terraform {
  backend "s3" {
    bucket = "tf-playground-state-vexus"
    key    = "terraform.tfstate"
    region = "us-east-2"
  }
}
```

### Automated Deployment Pipeline
- **Reliable Change Detection**: Uses `tj-actions/changed-files@v40` for accurate file change detection
- **Platform Selection**: Automatically selects ECS or EKS based on workflow input
- **Workspace Management**: Automatically selects appropriate Terraform workspace
- **Cost Optimization**: Only runs when infrastructure files change

### Development Workflow
1. **Create feature branch** from `develop`
2. **Make changes** to `environments/terraform/` files
3. **Push to feature branch** - triggers automatic dev deployment if files changed
4. **Create pull request** to `develop`
5. **Merge to develop** - triggers automatic staging deployment if files changed

### Production Promotion
1. **Create release branch** from `develop`
2. **Test in staging** environment
3. **Merge to main** - triggers production deployment (manual approval required)
4. **Tag release** for version tracking

### Workflow Features
- **Conditional Execution**: Steps only run when infrastructure files change
- **Platform Input**: Select ECS or EKS deployment platform
- **Workspace Isolation**: Each environment maintains separate state
- **Error Prevention**: Validates workspace exists before deployment

## 💰 Cost Optimization

### Current Monthly Costs (Estimated)
- **EC2 Instances**: $15-30 (t3.micro, minimal capacity)
- **RDS**: $15-25 (db.t3.micro)
- **ALB**: $20-25
- **Secrets Manager**: $0.80 (centralized approach)
- **Other**: $5-10
- **Total**: ~$55-90/month

### Cost Optimization Features
- **SSM Session Manager** (eliminates EC2 key pairs and SSH key management)
- **Parameter Store over Secrets Manager** (free SecureString vs $0.40/secret/month)
- **Minimal instance sizes** for demonstration
- **Auto-scaling** to reduce idle costs
- **Resource tagging** for cost tracking

### Access Management Strategy

**Zero SSH Key Management**: This project demonstrates modern AWS-native access patterns:

- **SSM Session Manager**: Secure shell access without SSH keys or open ports
- **IAM-based Authentication**: Access controlled through IAM roles and OIDC
- **No EC2 Key Pairs**: Eliminates key pair management overhead
- **Full Audit Trail**: All access logged through CloudTrail

**Secrets Storage**:
```
AWS Parameter Store (SecureString - Free):
└── /tf-playground/all/db-pword

No SSH Keys or EC2 Key Pairs Required!
```

**Production Note**: For production workloads, consider AWS Secrets Manager (~$0.40/secret/month) for automatic rotation and cross-region replication capabilities.

## 🔧 Configuration

### Platform Selection
Choose between ECS and EKS deployments with platform-specific configuration files:

#### ECS Configuration Files
```bash
# Development
working_ecs_dev.tfvars

# Staging  
working_ecs_staging.tfvars

# Production
working_ecs_production.tfvars
```

#### EKS Configuration Files
```bash
# Development
working_eks_dev.tfvars

# Staging
working_eks_staging.tfvars

# Production
working_eks_production.tfvars
```

### Sample Configuration
```hcl
# environments/terraform/working_ecs_production.tfvars
environment = "production"
aws_region  = "us-east-2"
platform    = "ecs"

# Instance configurations
webserver_instance_type = "t3.micro"
db_instance_type       = "db.t3.micro"

# ECS-specific settings
enable_ecs = true
enable_eks = false
enable_asg = false

# Auto Scaling Group settings
blue_desired_capacity  = 1
blue_max_size         = 2
blue_min_size         = 1
```

### Workspace-Based Deployment
Environments are separated using Terraform workspaces with a universal backend:

```bash
# Switch between environments
terraform workspace select dev
terraform workspace select staging
terraform workspace select production

# Each workspace maintains separate state
# S3 Backend: s3://tf-playground-state-vexus/env:/dev/terraform.tfstate
# S3 Backend: s3://tf-playground-state-vexus/env:/staging/terraform.tfstate
# S3 Backend: s3://tf-playground-state-vexus/env:/production/terraform.tfstate
```

### Customization
- **Platform selection** in `working_*_*.tfvars` files
- **Instance types** and sizing
- **Auto Scaling Group** capacities
- **Database** configurations
- **Network** CIDR ranges

## 📊 Monitoring and Validation

### Health Checks
- **Application health** endpoint: `/health`
- **Deployment validation** endpoint: `/deployment/validate`
- **Load balancer** health checks
- **Auto Scaling Group** health status

### Outputs
Each environment provides comprehensive outputs:
```bash
terraform output environment_summary
```

## 🔒 Security Considerations

### IAM Roles and Policies
- **Least privilege** access
- **Environment-specific** permissions
- **OIDC authentication** for CI/CD
- **Secrets rotation** capabilities

### Network Security
- **Private subnets** for databases
- **Security groups** with minimal access
- **SSL/TLS** termination at ALB
- **VPC isolation** between environments

## 🧪 Testing

### Local Testing
```bash
# Validate Terraform configuration
terraform validate

# Check formatting
terraform fmt -check

# Run security scan
terraform plan -out=tfplan
```

### Integration Testing
- **Automated deployment** testing
- **Health check** validation
- **Database connectivity** tests
- **Load balancer** functionality

## 📚 Documentation

- **[Complete Documentation Index](docs/README.md)** - Full documentation overview
- **[Blue-Green Deployment Implementation](docs/blue-green-deployment-project.md)** - Zero-downtime deployment patterns
- **[Strategic Direction & Lessons](docs/project-direction-and-lessons.md)** - Strategic thinking and lessons learned
- **[Centralized Secrets Optimization](docs/centralized-secrets-refactor.md)** - Cost optimization strategies
- **[Database Bootstrap Guide](docs/database-bootstrap.md)** - Automated database setup

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Test** thoroughly
5. **Submit** a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Career Benefits

This project demonstrates:

- **✅ Blue-Green Deployment Excellence** - Complete zero-downtime deployment implementation
- **✅ Enterprise Infrastructure Patterns** - Production-ready AWS automation
- **✅ CI/CD Pipeline Mastery** - GitFlow integration with automated validation
- **✅ Cost Optimization Strategy** - Zero-cost secrets via Parameter Store and keyless access via SSM
- **✅ Security Best Practices** - IAM, OIDC, encryption, and centralized secrets
- **✅ Strategic Decision Making** - Career-focused technology choices and prioritization
- **✅ Terraform Module Design** - Reusable, maintainable infrastructure components
- **✅ Production Operations** - Monitoring, alerting, and chaos testing

Perfect for showcasing completed implementations and strategic thinking in DevOps and Platform Engineering interviews.
# Staging Test Deployment
