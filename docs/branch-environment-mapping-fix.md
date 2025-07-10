# Branch-Environment Mapping Fix

## The Real Problem

The current CI/CD configuration has a **critical flaw** that allows module changes to trigger deployments to the wrong environment.

### Current Broken Behavior

```yaml
# When you push to develop branch with module changes:
develop branch + modules/** changes → staging environment ✅ (correct)
develop branch + modules/** changes → production environment ❌ (WRONG!)

# When you push to main branch with module changes:
main branch + modules/** changes → production environment ✅ (correct)  
main branch + modules/** changes → staging environment ❌ (WRONG!)
```

### Root Cause

Both workflows trigger on `modules/**` changes, which means:
- **develop branch** can affect production environment
- **main branch** can affect staging environment
- This violates the intended GitFlow workflow

## The Fix

### Option 1: Remove Module Triggers (Recommended)

Remove `modules/**` from the path triggers and rely on environment-specific changes:

```yaml
# .github/workflows/staging-terraform.yml
on:
  pull_request:
    branches: [develop]
    paths:
      - 'environments/staging/**'
      - '.github/workflows/staging-terraform.yml'
      - '!modules/oidc/**'
  push:
    branches: [develop]
    paths:
      - 'environments/staging/**'
      - '.github/workflows/staging-terraform.yml'
      - '!modules/oidc/**'

# .github/workflows/prod-terraform.yml
on:
  pull_request:
    branches: [main]
    paths:
      - 'environments/production/**'
      - '.github/workflows/prod-terraform.yml'
      - '!modules/oidc/**'
  push:
    branches: [main]
    paths:
      - 'environments/production/**'
      - '.github/workflows/prod-terraform.yml'
      - '!modules/oidc/**'
```

### Option 2: Environment-Specific Module Paths

Create environment-specific module directories:

```
modules/
├── staging/
│   ├── networking/
│   ├── compute/
│   └── database/
├── production/
│   ├── networking/
│   ├── compute/
│   └── database/
└── shared/
    └── oidc/
```

Then update triggers:

```yaml
# .github/workflows/staging-terraform.yml
on:
  push:
    branches: [develop]
    paths:
      - 'environments/staging/**'
      - 'modules/staging/**'
      - '.github/workflows/staging-terraform.yml'

# .github/workflows/prod-terraform.yml
on:
  push:
    branches: [main]
    paths:
      - 'environments/production/**'
      - 'modules/production/**'
      - '.github/workflows/prod-terraform.yml'
```

### Option 3: Manual Module Promotion

Keep module changes manual and require explicit promotion:

```yaml
# .github/workflows/staging-terraform.yml
on:
  push:
    branches: [develop]
    paths:
      - 'environments/staging/**'
      - '.github/workflows/staging-terraform.yml'
  workflow_dispatch:
    inputs:
      promote_modules:
        description: 'Promote module changes to staging'
        required: false
        default: 'false'

# .github/workflows/prod-terraform.yml
on:
  push:
    branches: [main]
    paths:
      - 'environments/production/**'
      - '.github/workflows/prod-terraform.yml'
  workflow_dispatch:
    inputs:
      promote_modules:
        description: 'Promote module changes to production'
        required: false
        default: 'false'
```

## Recommended Implementation

### Step 1: Immediate Fix (Option 1)

Remove `modules/**` from path triggers to prevent cross-environment contamination:

```yaml
# .github/workflows/staging-terraform.yml
on:
  pull_request:
    branches: [develop]
    paths:
      - 'environments/staging/**'
      - '.github/workflows/staging-terraform.yml'
      - '!modules/oidc/**'
  push:
    branches: [develop]
    paths:
      - 'environments/staging/**'
      - '.github/workflows/staging-terraform.yml'
      - '!modules/oidc/**'
```

### Step 2: Module Change Workflow

Create a separate workflow for module changes that requires manual approval:

```yaml
# .github/workflows/module-promotion.yml
name: Module Promotion

on:
  workflow_dispatch:
    inputs:
      target_environment:
        description: 'Target environment for module promotion'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
      module_path:
        description: 'Path to module being promoted'
        required: true
        type: string

jobs:
  promote-modules:
    name: Promote Modules to ${{ github.event.inputs.target_environment }}
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.12.0"

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123324351829:role/github-actions-global
          aws-region: us-east-2

      - name: Deploy to Staging
        if: github.event.inputs.target_environment == 'staging'
        working-directory: environments/staging
        run: |
          terraform init
          terraform apply -auto-approve

      - name: Deploy to Production
        if: github.event.inputs.target_environment == 'production'
        working-directory: environments/production
        run: |
          terraform init
          terraform apply -auto-approve
```

### Step 3: Documentation Update

Update your workflow documentation to reflect the new process:

```markdown
## Module Changes

Module changes require manual promotion:

1. **Development**: Test module changes in dev environment
2. **Staging**: Use "Module Promotion" workflow to promote to staging
3. **Production**: Use "Module Promotion" workflow to promote to production

This ensures:
- Module changes are tested before promotion
- No accidental cross-environment contamination
- Explicit approval for production module changes
```

## Benefits of This Fix

1. **Eliminates Cross-Environment Contamination**: develop branch can't affect production
2. **Enforces GitFlow**: Each branch only affects its intended environment
3. **Manual Module Control**: Module changes require explicit promotion
4. **Safer Deployments**: No accidental production deployments from develop branch

## Migration Steps

1. **Update staging-terraform.yml**: Remove `modules/**` from paths
2. **Update prod-terraform.yml**: Remove `modules/**` from paths
3. **Create module-promotion.yml**: New workflow for manual module promotion
4. **Test the changes**: Verify workflows only trigger on intended changes
5. **Update documentation**: Document the new module promotion process

## Verification

After implementing the fix, test these scenarios:

```bash
# Should trigger staging only
git checkout develop
echo "# test" >> environments/staging/main.tf
git commit -m "test staging change"
git push origin develop

# Should trigger production only  
git checkout main
echo "# test" >> environments/production/main.tf
git commit -m "test production change"
git push origin main

# Should NOT trigger either environment
git checkout develop
echo "# test" >> modules/networking/main.tf
git commit -m "test module change"
git push origin develop
``` 