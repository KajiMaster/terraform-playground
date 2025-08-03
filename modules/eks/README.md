# EKS Module

Terraform module for deploying Amazon EKS (Elastic Kubernetes Service) clusters with managed node groups.

## Features

- **EKS Cluster**: Managed Kubernetes control plane
- **Node Groups**: Managed EC2 instances for pod execution  
- **OIDC Provider**: For GitHub Actions integration
- **Security Groups**: Automatic cluster and pod networking
- **Cost Optimization**: Supports public subnet deployments for dev environments

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"
  
  environment = "dev"
  aws_region  = "us-east-2"
  
  # Network Configuration
  vpc_id         = module.networking.vpc_id
  subnet_ids     = module.networking.public_subnet_ids  # or private_subnet_ids
  
  # Node Configuration
  instance_types = ["t3.small"]
  min_size      = 1
  max_size      = 3
  desired_size  = 2
}
```

## Outputs

- `cluster_name`: EKS cluster name
- `cluster_endpoint`: Kubernetes API endpoint
- `cluster_security_group_id`: AWS-managed cluster security group ID
- `oidc_provider_arn`: OIDC provider for GitHub Actions

## Integration

Part of the **multi-pattern deployment architecture**. See [EKS Implementation Project](../../docs/eks-implementation-project.md) for complete implementation details.

## Database Bootstrap

Use the EKS database bootstrap script for consistent database initialization:

```bash
./eks-database-bootstrap.sh <environment>
```