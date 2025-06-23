# Sketch 4: State Management Hierarchy

## Overview

This sketch illustrates how Terraform state is managed using S3 for storage and DynamoDB for state locking across multiple environments.

## Visual Representation

```
┌─────────────────────────────────────────────────────────────┐
│                    STATE MANAGEMENT                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                S3 BUCKET                                │ │
│  │              tf-playground-state                        │ │
│  └─────────────────────────────────────────────────────────┘ │
│                              │                              │
│                              │                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   dev/      │    │  staging/   │    │ production/ │     │
│  │terraform.tf │    │terraform.tf │    │terraform.tf │     │
│  │   state     │    │   state     │    │   state     │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              DYNAMODB TABLE                             │ │
│  │              tf-playground-locks                        │ │
│  │              (State Locking)                            │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## State Management Components

### S3 Bucket

- **Name**: `tf-playground-state`
- **Purpose**: Store Terraform state files
- **Features**:
  - Versioning enabled
  - Server-side encryption
  - Access logging
  - Lifecycle policies

### State File Organization

```
tf-playground-state/
├── dev/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── production/
    └── terraform.tfstate
```

### DynamoDB Table

- **Name**: `tf-playground-locks`
- **Purpose**: State locking to prevent concurrent modifications
- **Features**:
  - Primary key: `LockID`
  - TTL for automatic cleanup
  - Consistent reads

## Backend Configuration

### Environment-Specific Backend Files

#### Dev Environment

```hcl
# environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket         = "tf-playground-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = true
  }
}
```

#### Staging Environment

```hcl
# environments/staging/backend.tf
terraform {
  backend "s3" {
    bucket         = "tf-playground-state"
    key            = "staging/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = true
  }
}
```

#### Production Environment

```hcl
# environments/production/backend.tf
terraform {
  backend "s3" {
    bucket         = "tf-playground-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = true
  }
}
```

## State Locking Mechanism

### How It Works

1. **Terraform Operation Starts**: `terraform apply`
2. **Lock Request**: DynamoDB table entry created
3. **Lock Acquired**: Operation proceeds
4. **Lock Released**: DynamoDB entry deleted

### Lock Table Structure

```
LockID: tf-playground-state/dev/terraform.tfstate
Info: {"ID":"12345","Operation":"OperationTypeApply","Info":"","Who":"user@example.com","Version":"1.5.0","Created":"2024-01-01 12:00:00.000000000 +0000 UTC","Path":"tf-playground-state/dev/terraform.tfstate"}
```

## Benefits

### 1. Team Collaboration

- Multiple developers can work safely
- No state file conflicts
- Concurrent operation prevention

### 2. Security

- Encrypted state storage
- Access control via IAM
- Audit trail via CloudTrail

### 3. Reliability

- State versioning in S3
- Automatic backup and recovery
- High availability

### 4. Scalability

- Supports multiple environments
- Easy to add new environments
- No local state file management

## Security Considerations

### IAM Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::tf-playground-state/*"
    },
    {
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"],
      "Resource": "arn:aws:dynamodb:*:*:table/tf-playground-locks"
    }
  ]
}
```

### Encryption

- **S3**: Server-side encryption with KMS
- **DynamoDB**: Encryption at rest
- **In Transit**: TLS encryption

## Cost Considerations

### S3 Costs

- **Storage**: ~$0.023 per GB per month
- **Requests**: Minimal for state files
- **Versioning**: Additional storage for history

### DynamoDB Costs

- **Read/Write Units**: Minimal for locking
- **Storage**: Minimal for lock entries
- **TTL**: Automatic cleanup reduces costs

This state management approach provides enterprise-grade reliability, security, and collaboration capabilities for the Terraform Playground project.
