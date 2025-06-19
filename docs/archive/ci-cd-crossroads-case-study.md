# CI/CD Crossroads Case Study: Terraform Playground Infrastructure Automation

## Executive Summary

This case study documents a critical architectural decision point in the Terraform Playground project where we needed to choose between multiple CI/CD approaches for automating database bootstrapping. The decision involved balancing technical requirements, enterprise considerations, and learning objectives.

## Project Context

### Background

- **Project**: Terraform Playground - A learning project demonstrating infrastructure as code best practices
- **Goal**: Create a fully automated web application infrastructure with database bootstrapping
- **Infrastructure**: AWS-based (VPC, EC2, RDS, IAM, SSM)
- **Challenge**: How to trigger database initialization after infrastructure deployment

### Technical Requirements

1. **Fully Automated**: No manual intervention required after `terraform apply`
2. **Enterprise-Ready**: Compatible with Terraform Cloud and production environments
3. **Secure**: No SSH keys or manual credential management
4. **Debuggable**: Clear logging and error handling
5. **Scalable**: Works across multiple environments (dev/stage/prod)

## The Crossroads Decision

### Problem Statement

After implementing SSM Automation for database bootstrapping, we faced a critical question:

> "How do we trigger the SSM Automation execution in a way that's compatible with enterprise CI/CD pipelines?"

### Initial Approach Analysis

#### Option 1: Terraform `local-exec` Provisioner

```hcl
resource "null_resource" "database_bootstrap" {
  provisioner "local-exec" {
    command = "aws ssm start-automation-execution --document-name ..."
  }
}
```

**Pros:**

- Simple to implement
- Runs automatically with `terraform apply`
- No additional infrastructure needed

**Cons:**

- ❌ **Breaks in Terraform Cloud** (no local AWS CLI access)
- ❌ **Not enterprise-ready** (depends on local execution)
- ❌ **Poor separation of concerns** (infrastructure vs. operational tasks)
- ❌ **Limited error handling and retry capabilities**

#### Option 2: Pure SSM Automation (Manual Trigger)

- Define SSM documents in Terraform
- Manually trigger via AWS CLI or console
- **Pros**: Clean separation, works everywhere
- **Cons**: Not fully automated, requires manual intervention

#### Option 3: User Data Scripts

- Embed database setup in EC2 user data
- **Pros**: Fully automated, no external dependencies
- **Cons**: Harder to debug, longer startup times, mixed responsibilities

## CI/CD Solution Analysis

### Decision Criteria

1. **Enterprise Compatibility**: Works with Terraform Cloud and remote execution
2. **Security**: Proper credential management and access controls
3. **Maintainability**: Easy to understand, debug, and modify
4. **Cost**: Reasonable pricing for learning/demo purposes
5. **Learning Value**: Demonstrates real-world patterns

### CI/CD Options Evaluated

#### 1. GitHub Actions

```yaml
# Example workflow structure
- name: Deploy Infrastructure
  run: terraform apply
- name: Trigger Database Bootstrap
  run: aws ssm start-automation-execution --document-name ...
```

**Pros:**

- ✅ Free for public repositories
- ✅ Easy to set up and understand
- ✅ Excellent GitHub integration
- ✅ Good documentation and community support
- ✅ Supports secrets management
- ✅ Can run AWS CLI commands

**Cons:**

- ❌ Requires storing AWS credentials as secrets
- ❌ Third-party dependency (not AWS-native)
- ❌ Limited to GitHub ecosystem

**Enterprise Fit:** High - Widely adopted, excellent for demos and many production teams

#### 2. AWS CodePipeline + CodeBuild

```yaml
# Example buildspec.yml
phases:
  build:
    commands:
      - terraform apply
      - aws ssm start-automation-execution --document-name ...
```

**Pros:**

- ✅ Fully AWS-native (no external dependencies)
- ✅ Integrates with IAM, S3, CodeCommit, CodeDeploy
- ✅ No need to expose AWS credentials to third parties
- ✅ Built-in integration with AWS services
- ✅ Enterprise-grade security and compliance

**Cons:**

- ❌ More complex initial setup
- ❌ Less flexible for non-AWS integrations
- ❌ Pay-per-use pricing (though minimal for demos)

**Enterprise Fit:** Very High - Common in AWS-centric organizations

#### 3. AWS CodeCatalyst

**Pros:**

- ✅ Newer, all-in-one AWS platform
- ✅ Combines source, build, and deploy
- ✅ Native AWS integration
- ✅ Simplified setup compared to CodePipeline

**Cons:**

- ❌ Still maturing
- ❌ Less widely adopted
- ❌ Limited documentation and community support

**Enterprise Fit:** Medium-High - Worth exploring for greenfield AWS projects

#### 4. Jenkins

**Pros:**

- ✅ Highly customizable
- ✅ Widely adopted in enterprises
- ✅ Extensive plugin ecosystem
- ✅ Self-hosted (full control)

**Cons:**

- ❌ Requires maintenance and infrastructure
- ❌ More complex setup
- ❌ Not AWS-native

**Enterprise Fit:** High - Common in larger organizations with hybrid needs

#### 5. GitLab CI/CD

**Pros:**

- ✅ Excellent GitLab integration
- ✅ Good documentation
- ✅ Self-hosted or SaaS options
- ✅ Built-in container registry

**Cons:**

- ❌ GitLab ecosystem dependency
- ❌ Not AWS-native

**Enterprise Fit:** High - Popular in enterprises using GitLab

## Recommended Architecture

### Final Decision: Hybrid Approach

**Infrastructure Layer (Terraform):**

- Define all AWS resources (VPC, EC2, RDS, IAM, SSM documents)
- Create SSM Automation document for database bootstrapping
- Set up IAM roles and policies for SSM execution

**CI/CD Layer (GitHub Actions for Demo, CodePipeline for Enterprise):**

- Run `terraform apply` with remote backend
- Trigger SSM Automation execution via AWS CLI
- Monitor and log execution results

### Implementation Strategy

#### Phase 1: GitHub Actions (Learning/Demo)

```yaml
name: Deploy Infrastructure
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
      - name: Terraform Init
        run: terraform init
      - name: Terraform Apply
        run: terraform apply -auto-approve
      - name: Trigger Database Bootstrap
        run: |
          aws ssm start-automation-execution \
            --document-name "dev-database-automation" \
            --parameters "DatabaseEndpoint=${{ steps.terraform.outputs.database_endpoint }}"
```

#### Phase 2: AWS CodePipeline (Enterprise)

```yaml
# buildspec.yml
version: 0.2
phases:
  install:
    runtime-versions:
      nodejs: 18
  pre_build:
    commands:
      - echo Installing Terraform...
      - wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
      - unzip terraform_1.5.0_linux_amd64.zip
      - mv terraform /usr/local/bin/
  build:
    commands:
      - echo Deploying infrastructure...
      - terraform init
      - terraform apply -auto-approve
      - echo Triggering database bootstrap...
      - aws ssm start-automation-execution --document-name "dev-database-automation"
```

## Key Learnings

### 1. Separation of Concerns

- **Terraform**: Infrastructure definition and resource creation
- **SSM Automation**: Operational tasks and configuration
- **CI/CD**: Orchestration and triggering

### 2. Enterprise Considerations

- **State Management**: Always use remote backends (S3, Terraform Cloud)
- **Credential Management**: Use IAM roles over access keys when possible
- **Audit Trail**: CI/CD provides better logging than local execution
- **Security**: AWS-native solutions reduce credential exposure

### 3. Trade-offs

- **Simplicity vs. Enterprise-Ready**: Local execution is simpler but not scalable
- **Cost vs. Features**: GitHub Actions is free but less integrated than AWS solutions
- **Learning vs. Production**: Different tools may be optimal for different stages

### 4. Interview Talking Points

- **Problem-Solving**: Demonstrate understanding of infrastructure automation challenges
- **Architecture Decisions**: Show ability to evaluate multiple solutions
- **Enterprise Awareness**: Understanding of production requirements
- **Technical Depth**: Knowledge of AWS services and CI/CD patterns

## Conclusion

This crossroads decision demonstrates the importance of considering enterprise requirements even in learning projects. The choice between CI/CD solutions involves balancing technical capabilities, security requirements, and organizational preferences.

**Key Takeaway**: The best solution depends on the context:

- **Learning/Demo**: GitHub Actions provides excellent value and ease of use
- **Enterprise/AWS-Centric**: CodePipeline offers deeper integration and security
- **Hybrid/Multi-Cloud**: Jenkins or GitLab CI/CD provide flexibility

The Terraform Playground project successfully demonstrates how to make these architectural decisions while maintaining learning objectives and preparing for real-world scenarios.

---

## Appendix: Implementation Files

### SSM Automation Document

```yaml
schemaVersion: "0.3"
assumeRole: "{{ AutomationAssumeRole }}"
description: "Automate database initialization with schema and sample data"
parameters:
  DatabaseEndpoint:
    type: String
  DatabaseName:
    type: String
  DatabaseUsername:
    type: String
  DatabasePassword:
    type: String
  InstanceId:
    type: String
mainSteps:
  - name: installDependencies
    action: "aws:runCommand"
    inputs:
      DocumentName: AWS-RunShellScript
      InstanceIds:
        - "{{ InstanceId }}"
      Parameters:
        commands:
          - yum install -y mariadb1011-client-utils
  # ... additional steps for schema creation and data insertion
```

### Terraform Module Structure

```
modules/
├── ssm/
│   ├── main.tf          # SSM documents and IAM roles
│   ├── variables.tf     # Input variables
│   └── outputs.tf       # Output values
├── compute/
├── database/
└── networking/
```

This case study demonstrates how to make informed architectural decisions while building practical, enterprise-ready infrastructure automation solutions.
