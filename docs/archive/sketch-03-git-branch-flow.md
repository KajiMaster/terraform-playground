# Sketch 3: Git Branch + Environment Flow

## Overview

This sketch illustrates the deployment pipeline from feature branch development through to production deployment.

## Visual Representation

```
┌─────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT PIPELINE                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐                                        │
│  │ feature/ssm-    │                                        │
│  │ database-       │                                        │
│  │ bootstrap       │                                        │
│  └─────────┬───────┘                                        │
│            │                                                │
│            │ Local Development                              │
│            │ terraform apply                                │
│            ▼                                                │
│  ┌─────────────────┐                                        │
│  │      DEV        │                                        │
│  │   Environment   │                                        │
│  │   (Testing)     │                                        │
│  └─────────┬───────┘                                        │
│            │                                                │
│            │ Merge to main                                  │
│            │ GitHub Actions                                 │
│            ▼                                                │
│  ┌─────────────────┐                                        │
│  │    STAGING      │                                        │
│  │   Environment   │                                        │
│  │ (Integration)   │                                        │
│  └─────────┬───────┘                                        │
│            │                                                │
│            │ Manual Approval                                │
│            │ Change Request                                 │
│            ▼                                                │
│  ┌─────────────────┐                                        │
│  │   PRODUCTION    │                                        │
│  │   Environment   │                                        │
│  │   (Live)        │                                        │
│  └─────────────────┘                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Flow Details

### Phase 1: Feature Development

- **Branch**: `feature/ssm-database-bootstrap`
- **Activity**: Local development and testing
- **Terraform**: `terraform plan` and `terraform apply`
- **Environment**: DEV (local/development)
- **Purpose**: Rapid iteration and testing

### Phase 2: Integration Testing

- **Trigger**: Merge feature branch to main
- **Automation**: GitHub Actions workflow
- **Environment**: STAGING
- **Purpose**: Integration testing and stakeholder review
- **Risk Level**: Medium (shared environment)

### Phase 3: Production Deployment

- **Trigger**: Manual approval process
- **Process**: Change Request (CR) and stakeholder communication
- **Environment**: PRODUCTION
- **Purpose**: Live production deployment
- **Risk Level**: High (requires planning and coordination)

## Key Principles

### 1. Progressive Risk Management

- **DEV**: Low risk, rapid iteration
- **STAGING**: Medium risk, integration testing
- **PRODUCTION**: High risk, planned deployment

### 2. Automated vs Manual

- **DEV**: Manual (developer control)
- **STAGING**: Automated (continuous integration)
- **PRODUCTION**: Manual approval (change management)

### 3. Stakeholder Involvement

- **DEV**: Developer only
- **STAGING**: Team review and testing
- **PRODUCTION**: Full stakeholder communication

## GitHub Actions Workflow

```yaml
name: Deploy Infrastructure
on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: "Environment to deploy to"
        required: true
        default: "staging"
        type: choice
        options: ["staging", "production"]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'staging' }}
    steps:
      - name: Deploy to Environment
        run: |
          cd environments/${{ github.event.inputs.environment || 'staging' }}
          terraform apply -auto-approve
```

## Benefits

### 1. Risk Mitigation

- Test changes in isolated environments
- Validate integration before production
- Planned production deployments

### 2. Quality Assurance

- Automated testing in staging
- Manual review before production
- Consistent deployment processes

### 3. Stakeholder Communication

- Clear deployment stages
- Planned production changes
- Reduced unplanned downtime

### 4. Team Collaboration

- Shared staging environment
- Integration testing
- Code review processes

## Change Management

### Production Deployment Requirements

- **Change Request**: Documented and approved
- **Stakeholder Communication**: Notify affected teams
- **Timing**: Scheduled during maintenance windows
- **Rollback Plan**: Prepared in case of issues
- **Testing**: Validated in staging environment

This workflow ensures safe, predictable, and well-communicated deployments across all environments.
