# Terraform Playground

A learning project focused on Terraform best practices, modular infrastructure, and environment management.

## Project Structure

```
terraform-playground/
├── environments/          # Environment-specific configurations
│   ├── dev/              # Development environment
│   ├── stage/            # Staging environment (to be added)
│   └── prod/             # Production environment (to be added)
├── modules/              # Reusable Terraform modules
│   ├── compute/          # Compute resources (EC2, etc.)
│   ├── database/         # Database resources (RDS)
│   └── networking/       # Networking resources (VPC, etc.)
├── docs/                 # Documentation
└── scripts/             # Utility scripts
```

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- SSH key pair for instance access (see [Key Management](docs/key-management.md))

## Getting Started

1. Clone the repository
2. Review and update `environments/dev/example.tfvars` as needed
3. Copy `example.tfvars` to `terraform.tfvars` (this file is gitignored)
4. Initialize Terraform:
   ```bash
   cd environments/dev
   terraform init
   ```
5. Review the plan:
   ```bash
   terraform plan
   ```

## Environment Management

This project uses Terraform Cloud for state management and team collaboration. Each environment (dev, stage, prod) has its own workspace in Terraform Cloud.

## Security

- SSH keys are managed separately from Terraform (see [Key Management](docs/key-management.md))
- Sensitive variables are managed through Terraform Cloud
- Database credentials are stored in AWS Parameter Store

## Contributing

1. Create a new branch for your changes
2. Make your changes
3. Submit a pull request
4. Ensure CI checks pass
5. Get review and approval
6. Merge to main

## License

MIT License
