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
- **Centralized Secrets Management** for cost optimization
- **Automated Database Bootstrapping** via AWS SSM
- **Security Best Practices** with IAM roles and OIDC

## 🏗️ Architecture

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Infrastructure                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Dev Env   │  │ Staging Env │  │Production Env│         │
│  │             │  │             │  │             │         │
│  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │         │
│  │ │   VPC   │ │  │ │   VPC   │ │  │ │   VPC   │ │         │
│  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │         │
│  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │         │
│  │ │   ALB   │ │  │ │   ALB   │ │  │ │   ALB   │ │         │
│  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │         │
│  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │         │
│  │ │Blue ASG │ │  │ │Blue ASG │ │  │ │Blue ASG │ │         │
│  │ │Green ASG│ │  │ │Green ASG│ │  │ │Green ASG│ │         │
│  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │         │
│  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │         │
│  │ │   RDS   │ │  │ │   RDS   │ │  │ │   RDS   │ │         │
│  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│              Centralized Resources                          │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ • SSH Keys (Shared across environments)                 │ │
│  │ • OIDC Provider (GitHub Actions)                        │ │
│  │ • S3 State Backend                                      │ │
│  │ • DynamoDB State Locking                                │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Centralized Secrets Management

**Cost Optimization**: Instead of creating separate secrets for each environment, this project uses a centralized approach:

#### Before (Expensive)
```
AWS Secrets Manager:
├── /tf-playground/dev/ssh-key
├── /tf-playground/dev/ssh-key-public  
├── /tf-playground/staging/ssh-key
├── /tf-playground/staging/ssh-key-public
├── /tf-playground/production/ssh-key
└── /tf-playground/production/ssh-key-public
```

#### After (Cost Optimized)
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

**Cost Savings**: 67% reduction in Secrets Manager costs ($1.60/month savings)

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
├── secrets/             # Secrets Manager integration
├── ssh-keys/            # Centralized SSH key management
├── ssm/                 # Systems Manager automation
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

### Pattern Selection
```hcl
# Development (Cost-Optimized)
enable_eks = true
enable_private_subnets = false  # Saves NAT gateway costs

# Production (Security-Focused)  
enable_ecs = true
enable_private_subnets = true   # Full network isolation
```

📖 **Detailed Implementation**: [EKS Implementation Project](docs/eks-implementation-project.md)

## 📁 Project Structure

```
terraform-playground/
├── environments/
│   ├── dev/              # Development environment
│   ├── staging/          # Staging environment
│   └── production/       # Production environment
├── modules/
│   ├── networking/       # Network infrastructure
│   ├── loadbalancer/     # Load balancer configuration
│   ├── compute/          # Compute resources
│   ├── database/         # Database resources
│   ├── secrets/          # Secrets management
│   ├── ssh-keys/         # Centralized SSH keys
│   ├── ssm/              # Systems Manager
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
cd ../dev
terraform init
terraform plan
   terraform apply
   ```

### 5. Access the Application
   ```bash
terraform output application_url
```

## 🔄 CI/CD Workflow

### Development Workflow
1. **Create feature branch** from `develop`
2. **Make changes** and test locally
3. **Push to feature branch** - triggers dev deployment
4. **Create pull request** to `develop`
5. **Merge to develop** - triggers staging deployment

### Production Promotion
1. **Create release branch** from `develop`
2. **Test in staging** environment
3. **Merge to main** - triggers production deployment
4. **Tag release** for version tracking

## 💰 Cost Optimization

### Current Monthly Costs (Estimated)
- **EC2 Instances**: $15-30 (t3.micro, minimal capacity)
- **RDS**: $15-25 (db.t3.micro)
- **ALB**: $20-25
- **Secrets Manager**: $0.80 (centralized approach)
- **Other**: $5-10
- **Total**: ~$55-90/month

### Cost Optimization Features
- **Centralized SSH keys** (67% secrets cost reduction)
- **Minimal instance sizes** for demonstration
- **Auto-scaling** to reduce idle costs
- **Resource tagging** for cost tracking

## 🔧 Configuration

### Environment Variables
Each environment has its own `terraform.tfvars` file:

```hcl
# environments/production/terraform.tfvars
environment = "production"
aws_region  = "us-east-2"

# Instance configurations
webserver_instance_type = "t3.micro"
db_instance_type       = "db.t3.micro"

# Auto Scaling Group settings
blue_desired_capacity  = 1
blue_max_size         = 2
blue_min_size         = 1
```

### Customization
- **Instance types** in `terraform.tfvars`
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
- **✅ Cost Optimization Strategy** - Measurable cost reductions (67% secrets cost savings)
- **✅ Security Best Practices** - IAM, OIDC, encryption, and centralized secrets
- **✅ Strategic Decision Making** - Career-focused technology choices and prioritization
- **✅ Terraform Module Design** - Reusable, maintainable infrastructure components
- **✅ Production Operations** - Monitoring, alerting, and chaos testing

Perfect for showcasing completed implementations and strategic thinking in DevOps and Platform Engineering interviews.
