# Sketch 1: Environment Hierarchy

## Overview

This sketch illustrates the three main environments in the Terraform Playground project and their key characteristics.

## Visual Representation

```
┌─────────────────────────────────────────────────────────────┐
│                    TERRAFORM PLAYGROUND                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │     DEV     │    │   STAGING   │    │ PRODUCTION  │     │
│  │ Environment │    │ Environment │    │ Environment │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         │                   │                   │           │
│         │                   │                   │           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │ 192.1.0.0/16│    │ 192.2.0.0/16│    │ 192.3.0.0/16│     │
│  │ t3.micro     │    │ t3.small    │    │ t3.medium   │     │
│  │ Full Setup   │    │ Full Setup  │    │ Full Setup  │     │
│  │ Public +     │    │ Public +    │    │ Public +    │     │
│  │ Private      │    │ Private     │    │ Private     │     │
│  │ + NAT        │    │ + NAT       │    │ + NAT       │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Environment Details

### DEV Environment

- **VPC CIDR**: `192.1.0.0/16`
- **Instance Type**: `t3.micro`
- **Network Setup**: Full setup with public and private subnets
- **NAT Gateway**: Present
- **Purpose**: Development and testing
- **Cost**: Minimal (small instances)

### STAGING Environment

- **VPC CIDR**: `192.2.0.0/16`
- **Instance Type**: `t3.small`
- **Network Setup**: Full setup with public and private subnets
- **NAT Gateway**: Present
- **Purpose**: Integration testing and stakeholder review
- **Cost**: Medium

### PRODUCTION Environment

- **VPC CIDR**: `192.3.0.0/16`
- **Instance Type**: `t3.medium`
- **Network Setup**: Full setup with public and private subnets
- **NAT Gateway**: Present
- **Purpose**: Live production environment
- **Cost**: Higher (larger instances)

## Key Principles

1. **Same Architecture**: All environments use identical network architecture
2. **Different Scales**: Instance sizes and resource allocations vary
3. **Isolated Networks**: Each environment has its own VPC with unique CIDR ranges
4. **Consistent Patterns**: Same security groups, routing, and deployment patterns

## Benefits

- **Predictable Deployments**: Same infrastructure patterns across environments
- **Easy Testing**: Staging mirrors production architecture
- **Cost Optimization**: Smaller resources in non-production environments
- **Security**: Network isolation between environments
