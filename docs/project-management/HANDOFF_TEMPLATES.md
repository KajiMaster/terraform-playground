# Handoff Templates

Templates for seamless coordination between Claude Code and Cursor.

## Starting a Cursor Session

**Quick Context Check:**
```
1. Check CURRENT_WORK.md for active tasks
2. Run: git status
3. Review recent commits: git log --oneline -5
4. Check current sprint in CLAUDE.md
```

**Sample Cursor Prompt:**
```
I'm continuing work on [PROJECT/FEATURE]. 

Current context from CURRENT_WORK.md:
- Active task: [TASK_DESCRIPTION]
- Recent changes: [BRIEF_SUMMARY]
- Current focus: [FOCUS_AREA]

I need to [SPECIFIC_OBJECTIVE]. The codebase uses [TECH_STACK] and I'm working in [ENVIRONMENT].

Key files to focus on: [FILE_LIST]
```

## Ending a Cursor Session

**Update Checklist:**
- [ ] Update CURRENT_WORK.md with progress
- [ ] Commit changes with descriptive messages  
- [ ] Note any blockers or next steps
- [ ] Update sprint status in CLAUDE.md if major milestone reached

**Handoff Note Template:**
```markdown
## Session Summary
**Duration**: [TIME]
**Files Modified**: [LIST]
**Completed**: [ACCOMPLISHMENTS]
**Next Steps**: [IMMEDIATE_NEXT_ACTIONS]
**Blockers**: [ISSUES_TO_RESOLVE]
**Testing Status**: [WHAT_WAS_TESTED]
```

## Starting a Claude Code Session

**Context Recovery:**
```
1. Read CURRENT_WORK.md for latest status
2. Check git status and recent commits
3. Review any open GitHub issues
4. Assess current infrastructure state
```

**Claude Coordination:**
- Update TodoWrite with current task breakdown
- Maintain project overview and technical decisions
- Handle cross-cutting concerns and architecture
- Coordinate between multiple work streams

## Emergency Handoffs

**When Blocking Issues Arise:**
```markdown
## BLOCKER ALERT
**Issue**: [SPECIFIC_PROBLEM]
**Impact**: [WHAT_IS_AFFECTED]
**Attempted Solutions**: [WHAT_WAS_TRIED]
**Next Actions**: [SUGGESTED_APPROACH]
**Urgency**: [LOW/MEDIUM/HIGH/CRITICAL]
```

## Feature Completion Handoff

**Completion Checklist:**
- [ ] Feature implemented and tested
- [ ] Documentation updated
- [ ] CI/CD pipeline validated
- [ ] Security review completed (if applicable)
- [ ] Performance impact assessed
- [ ] Ready for review/deployment

**Handoff to Production:**
```markdown
## Production Readiness
**Feature**: [FEATURE_NAME]
**Testing**: [ENVIRONMENTS_TESTED]
**Performance**: [IMPACT_ASSESSMENT]
**Security**: [REVIEW_STATUS]
**Deployment Plan**: [BLUE_GREEN_STRATEGY]
**Rollback Plan**: [CONTINGENCY]
```

## Integration Patterns

### Infrastructure Changes
```bash
# Standard validation before handoff
terraform validate
terraform plan -var-file=staging.tfvars
# Test in staging first
```

### Application Changes  
```bash
# Local testing before handoff
cd app && ./test-local.sh
# Container validation
docker compose up -d && docker compose down -v
```

### CI/CD Updates
```bash
# Workflow validation
# Check GitHub Actions tab after pushing
# Verify OIDC authentication working
```

---
*These templates ensure consistent handoffs and maintain project velocity*