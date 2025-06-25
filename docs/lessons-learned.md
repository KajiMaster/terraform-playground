# Lessons Learned - Real Human Notes

## Terraform Dependencies

### Resource References vs Variables
**Problem**: EC2 instance failing with "key pair doesn't exist"

**Wrong way:**
```hcl
key_name = var.key_name  # Just a string, assumes key exists
```

**Right way:**
```hcl
key_name = aws_key_pair.webserver.key_name  # References the resource being created
```

**Why it matters**: Terraform creates implicit dependencies. EC2 waits for key pair to be created first.

**Lesson**: Always reference resources you're creating, not external resources you assume exist.

---

## GitOps Flow Issues

### The "Duplication" Problem
**What happened**: Saw staging steps in production PR comments

**Reality**: GitHub UI caching + both workflows triggering on module changes

**Lesson**: Sometimes it's GitHub being weird, not your GitFlow being broken

**Test it**: Create fresh PR, see if behavior repeats

---

## Environment Isolation

### Key Pair Naming Conflicts
**Problem**: Both dev and staging trying to use same key name

**Root cause**: terraform.tfvars overriding variables.tf defaults

**Fix**: 
- variables.tf: `key_name = "tf-playground-dev"`
- terraform.tfvars: `key_name = "tf-playground-dev"` (not generic name)

**Lesson**: Check terraform.tfvars when variables aren't working as expected

---

## Strategic Decision Making

### When to Add Complexity
**Question**: "Do I need this advanced feature right now?"

**Good reasons to add complexity**:
- High demand skill (blue-green deployments)
- Solves real problem you're having
- Direct career impact

**Bad reasons**:
- "It sounds cool"
- "Other people use it"
- "Might need it someday"

**Lesson**: Start simple, add complexity when you actually need it

### Cost vs Learning Value
**KMS Migration**: Worth it - eliminated $2.80/month costs
**Blue-Green Deployments**: Worth it - high demand skill
**Module Versioning**: Not worth it yet - adds complexity, no immediate benefit

**Lesson**: Every feature should either solve a problem or advance your career

---

## Common Patterns

### When to Use Resource References
- **Creating resources**: Use `resource_name.attribute`
- **External dependencies**: Use `var.variable_name` (but be careful)

### When Terraform Fails
1. Check terraform.tfvars first
2. Look for dependency issues
3. Verify resource names aren't conflicting
4. Check if external resources actually exist

### GitFlow Gotchas
- Module changes trigger both staging and production
- GitHub UI can be confusing
- Sometimes the "problem" is just UI caching

---

## Quick Debugging Checklist

1. **Resource doesn't exist error**: Check if you're referencing external vs internal resource
2. **Variable not working**: Check terraform.tfvars for overrides
3. **GitOps weirdness**: Create fresh PR to test
4. **Dependency issues**: Use resource references instead of variable references

---

## Notes for Future Me

- Don't overthink GitOps issues - test with fresh PR first
- Always check terraform.tfvars when variables seem wrong
- Resource references > variable references for internal dependencies
- GitHub UI can be misleading - trust the actual infrastructure state
- Start simple, add complexity when you actually need it
- Every feature should solve a problem or advance your career

---

*This is a living document. Add real lessons as they happen.* 