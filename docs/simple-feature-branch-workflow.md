# Simple Feature Branch Workflow

## Overview

This document describes a simple, practical approach to feature branch development for the Terraform playground project.

## Current Status

You're currently on `feature/ssm-database-bootstrap` and it's **working perfectly**. This document helps you understand when to create new branches vs. continue on the current one.

## Simple Branch Strategy

### When to Stay on Current Branch

```
feature/ssm-database-bootstrap
├── Still working on SSM automation? → Stay here
├── Still working on database bootstrapping? → Stay here
├── Still working on related database features? → Stay here
└── Adding more SSM documents? → Stay here
```

### When to Create New Branch

```
feature/ssm-database-bootstrap (current)
├── Want to add load balancer? → feature/load-balancer
├── Want to add monitoring? → feature/monitoring
├── Want to add caching? → feature/caching
└── Want to add security groups? → feature/security-groups
```

## Basic Workflow

### 1. **Continue Current Work**

```bash
# You're on feature/ssm-database-bootstrap
# Keep working on SSM and database stuff
git add .
git commit -m "Add more SSM automation features"
```

### 2. **Start New Feature**

```bash
# When ready for a different feature
git checkout main
git pull origin main
git checkout -b feature/load-balancer
# Work on load balancer...
```

### 3. **Finish Current Feature**

```bash
# When SSM/database work is complete
git checkout feature/ssm-database-bootstrap
git add .
git commit -m "Complete SSM database bootstrap"
git push origin feature/ssm-database-bootstrap
# Create PR to main
```

## Simple Rules

### ✅ **Stay on Current Branch If:**

- Working on related features
- Same general area (SSM, database, etc.)
- Small incremental improvements
- Bug fixes for current feature

### ✅ **Create New Branch If:**

- Completely different feature area
- Major architectural changes
- Unrelated functionality
- Want to experiment without affecting current work

## Example Scenarios

### Scenario 1: Continue Current Work

```bash
# You're on feature/ssm-database-bootstrap
# Adding more database tables to the bootstrap
git add .
git commit -m "Add user management tables to bootstrap"
# Stay on this branch - it's related work
```

### Scenario 2: Start New Feature

```bash
# You're on feature/ssm-database-bootstrap
# Want to add a load balancer (completely different)
git checkout main
git pull origin main
git checkout -b feature/load-balancer
# Now working on load balancer
```

### Scenario 3: Finish and Start New

```bash
# SSM/database work is complete
git checkout feature/ssm-database-bootstrap
git add .
git commit -m "Complete SSM database bootstrap"
git push origin feature/ssm-database-bootstrap
# Create PR, merge to main

# Start new feature
git checkout main
git pull origin main
git checkout -b feature/monitoring
# Work on monitoring...
```

## Environment Management

### Simple Approach

- **One environment at a time** (keep it simple)
- **Destroy when switching** major features
- **Keep environment for related work**

### Example

```bash
# Working on SSM/database
cd environments/dev
terraform apply -auto-approve
# Work on SSM features...

# Want to work on load balancer?
terraform destroy -auto-approve
git checkout -b feature/load-balancer
terraform apply -auto-approve
# Work on load balancer...
```

## Best Practices

### 1. **Keep Branches Focused**

- One major feature per branch
- Related changes can stay together
- Don't mix unrelated features

### 2. **Commit Frequently**

```bash
git add .
git commit -m "Add database user table"
git commit -m "Fix SSM automation timeout"
git commit -m "Add error handling to bootstrap"
```

### 3. **Use Descriptive Names**

```bash
feature/ssm-database-bootstrap    # ✅ Clear
feature/load-balancer-setup       # ✅ Clear
feature/feature                   # ❌ Unclear
```

### 4. **Test Before PR**

```bash
# Test your changes
terraform plan
terraform apply -auto-approve
# Test the functionality
# Then create PR
```

## When You're Ready for Staging

### Complete Feature

```bash
# On your feature branch
git add .
git commit -m "Complete [feature-name]"
git push origin feature/[feature-name]
```

### Create Pull Request

1. Go to GitHub
2. Create PR from `feature/[feature-name]` to `main`
3. PR will trigger staging deployment
4. Review and merge when ready

### Environment Cleanup

- GitHub Actions will automatically clean up your dev environment
- No manual cleanup needed
- Cost savings happen automatically

## Troubleshooting

### Common Issues

1. **Want to switch features but have uncommitted changes**

   ```bash
   git stash
   git checkout -b feature/new-feature
   git stash pop  # When ready to continue
   ```

2. **Environment conflicts**

   ```bash
   terraform destroy -auto-approve
   git checkout -b feature/new-feature
   terraform apply -auto-approve
   ```

3. **Not sure if you should create new branch**
   - **Related work**: Stay on current branch
   - **Different area**: Create new branch
   - **When in doubt**: Create new branch (safer)

## Summary

### Keep It Simple

- **Current branch**: `feature/ssm-database-bootstrap` (working great!)
- **Related work**: Stay on current branch
- **New features**: Create new branches
- **One environment**: At a time
- **Frequent commits**: Small, focused changes

### Your Current Status

✅ **SSM database bootstrap is working**
✅ **Environment is stable**
✅ **Ready to continue or branch out**

**Bottom line**: You're doing great! Keep working on `feature/ssm-database-bootstrap` until you want to work on something completely different, then create a new branch.
