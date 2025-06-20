# SSH Modernization Notes

## Current State

- Using SSH key pairs for EC2 access
- Public IPs and port 22 open
- Legacy but functional approach

## Modern Approach (Future)

### Replace SSH with SSM Session Manager

**Current SSH Access:**

```bash
ssh -i ~/.ssh/tf-playground-staging.pem ec2-user@<public-ip>
```

**Modern SSM Access:**

```bash
aws ssm start-session --target i-1234567890abcdef0
```

### Changes Needed:

1. **Remove from EC2 instance:**
   - `key_name = var.key_name`
2. **Remove from security group:**
   - SSH ingress rule (port 22)
3. **Remove Elastic IP:**
   - Instances can be in private subnets
4. **Already configured:**
   - IAM role with `AmazonSSMManagedInstanceCore` policy
   - SSM automation working

### Benefits:

- ✅ No SSH keys to manage
- ✅ Better audit trail
- ✅ More secure (no public IPs)
- ✅ IAM-based access control
- ✅ Automatic key rotation

### When to implement:

- After current workflow is stable
- During next major refactor
- When adding new environments
