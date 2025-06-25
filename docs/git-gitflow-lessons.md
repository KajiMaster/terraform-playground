# Git & GitFlow Lessons Learned

> **🎯 Purpose**: Practical Git and GitFlow workflows learned through hands-on experience. This document serves as a quick reference for common scenarios and helps build muscle memory for team development.

## Table of Contents

1. [Core Git Concepts](#core-git-concepts)
2. [GitFlow Workflow](#gitflow-workflow)
3. [Common Scenarios](#common-scenarios)
4. [Troubleshooting](#troubleshooting)
5. [Best Practices](#best-practices)
6. [Team Development Patterns](#team-development-patterns)

## Core Git Concepts

### Branch Types

- **`main`**: Production-ready code (live environment)
- **`develop`**: Integration branch (staging environment)
- **`feature/*`**: Individual developer work (dev environment)
- **`hotfix/*`**: Emergency production fixes
- **`release/*`**: Preparation for production release

### Key Commands

```bash
# Check current branch and status
git status
git branch

# See all branches (local and remote)
git branch -a

# Switch branches
git checkout <branch-name>
git checkout -b <new-branch-name>  # Create and switch

# See commit history
git log --oneline
git log --graph --oneline --all
```

## GitFlow Workflow

### Daily Development Cycle

#### 1. Start New Feature
```bash
# Ensure you're on develop and it's up to date
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/your-feature-name

# Work on your feature...
```

#### 2. Complete Feature
```bash
# Stage and commit your changes
git add .
git commit -m "Descriptive commit message"

# Push feature branch
git push origin feature/your-feature-name

# Create PR to develop (GitHub web interface)
```

#### 3. After PR is Merged
```bash
# Clean up local feature branch
git checkout develop
git pull origin develop
git branch -d feature/your-feature-name
```

### Production Deployment Cycle

#### 1. Deploy to Production
```bash
# Create PR from develop to main
# (GitHub web interface)

# After PR is merged to main
git checkout main
git pull origin main
```

# Note: develop stays ahead of main - this is normal and expected
# No need to sync them back and forth

## Common Scenarios

### Scenario 1: You Have Uncommitted Changes But Need to Switch Branches

```bash
# Option A: Stash changes
git stash push -m "WIP: describe what you're working on"
git checkout other-branch
# ... do work ...
git checkout original-branch
git stash pop

# Option B: Commit changes
git add .
git commit -m "WIP: describe what you're working on"
git checkout other-branch
```

### Scenario 2: You Need to Update Your Feature Branch with Latest Develop

```bash
# Method A: Merge develop into feature (preserves history)
git checkout feature/your-feature
git merge develop

# Method B: Rebase feature on develop (cleaner history)
git checkout feature/your-feature
git rebase develop
```

### Scenario 3: You Made Changes on Wrong Branch

```bash
# Stash changes from wrong branch
git stash push -m "Changes meant for feature branch"

# Switch to correct branch
git checkout feature/correct-branch

# Apply changes
git stash pop
```

### Scenario 4: You Need to Undo Last Commit

```bash
# Undo commit but keep changes staged
git reset --soft HEAD~1

# Undo commit and unstage changes
git reset HEAD~1

# Undo commit and discard changes (DANGEROUS)
git reset --hard HEAD~1
```

### Scenario 5: You Need to Fix a Commit Message

```bash
# Fix last commit message
git commit --amend -m "New commit message"

# Fix older commit (interactive rebase)
git rebase -i HEAD~3  # Shows last 3 commits
# Change 'pick' to 'reword' for the commit you want to fix
```

## Troubleshooting

### "Your branch is behind 'origin/develop' by X commits"

```bash
# Update your branch with latest develop
git checkout develop
git pull origin develop
git checkout your-feature-branch
git merge develop
```

### "Your branch and 'origin/develop' have diverged"

```bash
# This means both branches have new commits
# Option A: Merge (preserves both histories)
git merge develop

# Option B: Rebase (replays your commits on top of develop)
git rebase develop
```

### "Cannot lock ref 'refs/heads/develop': ref is at X but expected Y"

```bash
# This happens when someone else pushed to develop while you were working
git fetch origin
git reset --hard origin/develop
# WARNING: This discards any local changes to develop
```

### "Merge conflict in file.txt"

```bash
# 1. Open the conflicted file and resolve conflicts
# 2. Stage the resolved file
git add file.txt

# 3. Continue the merge/rebase
git commit  # for merge
# OR
git rebase --continue  # for rebase
```

## Best Practices

### Commit Messages
```bash
# Good commit messages
git commit -m "Add user authentication feature"
git commit -m "Fix database connection timeout issue"
git commit -m "Update README with deployment instructions"

# Bad commit messages
git commit -m "fix"
git commit -m "stuff"
git commit -m "updates"
```

### Branch Naming
```bash
# Good branch names
feature/user-authentication
feature/database-optimization
hotfix/security-patch
release/v2.1.0

# Bad branch names
feature
fix
new
test
```

### When to Commit
- ✅ After completing a logical unit of work
- ✅ Before switching branches
- ✅ Before pulling/pushing
- ✅ When you need to save your work

### When to Create New Branches
- ✅ Starting work on a new feature
- ✅ Fixing a bug
- ✅ Making changes that aren't related to current work
- ✅ When you're unsure - it's safer to create a branch

## Team Development Patterns

### Solo Developer Workflow
```bash
# Simplified workflow for solo development
git checkout develop
git pull origin develop
git checkout -b feature/new-feature
# ... work ...
git add .
git commit -m "Add new feature"
git push origin feature/new-feature
# Create PR to main (skip develop for solo work)
```

### Team Development Workflow
```bash
# Full GitFlow for team development
git checkout develop
git pull origin develop
git checkout -b feature/new-feature
# ... work ...
git add .
git commit -m "Add new feature"
git push origin feature/new-feature
# Create PR to develop
# After merge, create PR from develop to main
```

### Code Review Process
1. Create feature branch from develop
2. Make changes and commit
3. Push branch and create PR to develop
4. Request review from team members
5. Address feedback and push updates
6. Merge to develop after approval
7. Deploy to staging (automatic via CI/CD)
8. Create PR from develop to main for production

## Quick Reference Commands

### Daily Commands
```bash
git status                    # Check current state
git checkout develop          # Switch to develop
git pull origin develop       # Update develop
git checkout -b feature/name  # Create feature branch
git add .                     # Stage all changes
git commit -m "message"       # Commit changes
git push origin branch-name   # Push branch
```

### Emergency Commands
```bash
git stash                     # Save work temporarily
git stash pop                 # Restore saved work
git reset --hard HEAD         # Discard all changes (DANGEROUS)
git log --oneline -10         # See recent commits
git branch -a                 # List all branches
```

### Cleanup Commands
```bash
git branch -d branch-name     # Delete local branch
git branch -D branch-name     # Force delete local branch
git remote prune origin       # Clean up remote tracking branches
```

## Lessons Learned

### What Works Well
- ✅ Always start from an updated develop branch
- ✅ Create feature branches for any significant work
- ✅ Commit frequently with descriptive messages
- ✅ Use stashes when you need to switch branches quickly
- ✅ Keep develop and main in sync after production deployments

### What to Avoid
- ❌ Working directly on develop or main
- ❌ Making multiple unrelated changes in one commit
- ❌ Force pushing to shared branches
- ❌ Letting branches get too far behind develop
- ❌ Merging without resolving conflicts properly

### Common Mistakes
- Making changes on wrong branch
- Forgetting to pull latest changes before starting work
- Not committing frequently enough
- Using vague commit messages
- Not cleaning up old branches

## Mental Models

### Git as a Timeline
- Each commit is a snapshot in time
- Branches are parallel timelines
- Merging combines timelines
- Rebasing replays your timeline on top of another

### Git as a Tree
- Main trunk = main branch
- Major branches = develop, release branches
- Small branches = feature branches
- Leaves = individual commits

### Git as a Backup System
- Every commit is a backup
- Branches are different versions
- You can always go back to any previous state
- Stashes are temporary backups

---

**Remember**: Git is a tool, not a religion. Use the workflow that works best for your team and project. These patterns are guidelines, not rules. 