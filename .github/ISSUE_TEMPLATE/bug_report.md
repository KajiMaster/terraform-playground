---
name: Bug Report
about: Report a bug or issue
title: '[BUG] '
labels: ['bug', 'needs-triage']
assignees: ''
---

## Bug Description
<!-- Clear description of what the bug is -->

## Environment
- **Affected Environment**: [ ] dev [ ] staging [ ] production [ ] local
- **Infrastructure Component**: <!-- e.g., loadbalancer, database, ecs -->
- **Application Component**: <!-- e.g., health checks, API endpoints -->

## Steps to Reproduce
1. 
2. 
3. 

## Expected Behavior
<!-- What should happen -->

## Actual Behavior
<!-- What actually happens -->

## Error Messages/Logs
```
<!-- Paste relevant error messages or logs -->
```

## Impact Assessment
- [ ] Critical - Production down
- [ ] High - Major functionality broken
- [ ] Medium - Some functionality impaired
- [ ] Low - Minor issue

## Investigation Notes
### Infrastructure Check
- [ ] Terraform state consistent
- [ ] AWS resources healthy
- [ ] Load balancer status
- [ ] Database connectivity

### Application Check
- [ ] Container logs reviewed
- [ ] Health endpoints responding
- [ ] Database queries working
- [ ] API endpoints functional

## Potential Root Cause
<!-- Initial thoughts on what might be causing this -->

## Workaround
<!-- Temporary solution if available -->

---
*For tool coordination: Update CURRENT_WORK.md when investigating this issue*