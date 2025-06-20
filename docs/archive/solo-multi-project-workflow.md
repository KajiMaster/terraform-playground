# Solo Developer Multi-Project Workflow (ARCHIVED)

## Overview

This document describes how a solo developer can leverage the team infrastructure to manage multiple concurrent projects, treating each project as a "virtual developer" for maximum productivity and project isolation.

## The Concept: You as Multiple "Virtual Developers"

### Traditional Solo Development:

```
You → One Project → Linear Progress
```

### Enhanced Solo Multi-Project Development:

```
You (Solo Developer) = Multiple "Virtual Developers"
├── "Developer Alice" → Project A (Database Optimization)
├── "Developer Bob" → Project B (Load Balancer)
├── "Developer Charlie" → Project C (Monitoring)
└── "Developer Diana" → Project D (Caching Layer)
```

## Why This Approach is Powerful

### 1. **Project Isolation**

- Each project has its own environment, state file, and resources
- No conflicts between different projects
- Clean separation of concerns

### 2. **Context Switching**

- Work on Project A until stuck/bored
- Switch to Project B for fresh perspective
- Return to Project A with new ideas
- Maintain momentum across multiple projects

### 3. **Independent Lifecycles**

- Project A: Ready for staging
- Project B: Still in development
- Project C: Paused (saved for later)
- Project D: Just started

### 4. **Cost Management**

- Only run environments for active projects
- Pause/destroy environments when switching
- Automatic cleanup when projects are complete

## Project Management Tool

### Using the Project Switcher Script

The `scripts/project-switcher.sh` script provides a complete interface for managing multiple projects:

```bash
# List all projects and their status
./scripts/project-switcher.sh list

# Start a new project
./scripts/project-switcher.sh start database-optimization

# Switch to an existing project
./scripts/project-switcher.sh switch load-balancer

# Pause a project (destroy environment, save code)
./scripts/project-switcher.sh pause monitoring

# Resume a paused project
./scripts/project-switcher.sh resume caching

# Mark project ready for staging
./scripts/project-switcher.sh finish database-optimization

# Check project status
./scripts/project-switcher.sh status load-balancer

# Destroy project completely
./scripts/project-switcher.sh destroy old-project
```

## Workflow Examples

### Example 1: Starting Multiple Projects

```bash
# Start Project A: Database Optimization
./scripts/project-switcher.sh start database-optimization
# Work on database performance improvements...

# Get stuck? Start Project B: Load Balancer
./scripts/project-switcher.sh start load-balancer
# Work on load balancer setup...

# Switch back to Project A
./scripts/project-switcher.sh switch database-optimization
# Continue with fresh perspective...
```

### Example 2: Context Switching Strategy

```bash
# Morning: Work on database optimization
./scripts/project-switcher.sh switch database-optimization
# Make progress on database queries...

# Afternoon: Switch to load balancer (different mental context)
./scripts/project-switcher.sh switch load-balancer
# Work on load balancer configuration...

# Evening: Return to database with new insights
./scripts/project-switcher.sh switch database-optimization
# Apply learnings from load balancer work...
```

### Example 3: Project Lifecycle Management

```bash
# Project A is ready for staging
./scripts/project-switcher.sh finish database-optimization
git push origin feature/database-optimization
# Create PR → Staging deployment → Production

# Project B still in development
./scripts/project-switcher.sh switch load-balancer
# Continue working...

# Project C paused (save for later)
./scripts/project-switcher.sh pause monitoring
# Environment destroyed, code saved in branch

# Project D just started
./scripts/project-switcher.sh start caching
# Begin new project...
```

## Project States and Transitions

### Project State Machine

```
PLANNED → ACTIVE → PAUSED → ACTIVE → READY → COMPLETE
   ↓        ↓        ↓        ↓        ↓
  start   switch   resume   finish   PR merged
```

### State Descriptions

- **PLANNED**: Project defined but not started
- **ACTIVE**: Environment running, actively being worked on
- **PAUSED**: Environment destroyed, code saved in branch
- **READY**: Project complete, ready for staging deployment
- **COMPLETE**: Merged to main, deployed to production

## Cost Optimization for Solo Development

### Resource Management Strategy

#### 1. **Only Run Active Projects**

```bash
# Only one environment running at a time
./scripts/project-switcher.sh switch project-a  # Environment A running
./scripts/project-switcher.sh switch project-b  # Environment A destroyed, B running
```

#### 2. **Automatic Cleanup**

- GitHub Actions destroys environments when PRs are merged
- No manual cleanup required
- Cost savings happen automatically

#### 3. **Small Resources for Development**

```hcl
# environments/dev/variables.tf
variable "webserver_instance_type" {
  default = "t3.micro"  # Smallest instance for solo dev
}

variable "db_instance_type" {
  default = "db.t3.micro"  # Smallest DB for solo dev
}
```

## Project Organization

### Predefined Projects

The project switcher comes with predefined projects:

```json
{
  "database-optimization": {
    "developer": "alice",
    "description": "Database performance improvements",
    "status": "active"
  },
  "load-balancer": {
    "developer": "bob",
    "description": "Application load balancer setup",
    "status": "active"
  },
  "monitoring": {
    "developer": "charlie",
    "description": "CloudWatch monitoring and alerts",
    "status": "paused"
  },
  "caching": {
    "developer": "diana",
    "description": "Redis caching layer implementation",
    "status": "planned"
  }
}
```

### Adding Custom Projects

```bash
# Edit .projects.json to add your own projects
{
  "my-custom-project": {
    "developer": "custom-dev",
    "description": "My custom project description",
    "status": "planned"
  }
}
```

## Best Practices

### 1. **Context Switching**

- Switch projects when stuck or bored
- Use different mental contexts for different projects
- Return to projects with fresh perspective

### 2. **Project Focus**

- Work on one project at a time (one environment active)
- Complete logical chunks before switching
- Use project status to track progress

### 3. **Code Management**

- Each project has its own feature branch
- Commit frequently within each project
- Use descriptive commit messages

### 4. **Environment Management**

- Pause projects when not actively working
- Destroy environments to save costs
- Resume projects when ready to continue

### 5. **Staging Integration**

- Mark projects as "ready" when complete
- Create PRs for staging deployment
- Let automated cleanup handle environment destruction

## Advanced Workflows

### Parallel Development (Advanced)

For experienced users, you can run multiple environments simultaneously:

```bash
# Terminal 1: Work on database optimization
./scripts/project-switcher.sh switch database-optimization
# Environment A running

# Terminal 2: Work on load balancer (different AWS profile/region)
export AWS_PROFILE=project-b
./scripts/project-switcher.sh switch load-balancer
# Environment B running in different account/region
```

### Project Dependencies

Some projects may depend on others:

```bash
# Project A: Core infrastructure
./scripts/project-switcher.sh start core-infra
# Deploy base networking, security groups

# Project B: Depends on Project A
./scripts/project-switcher.sh start app-layer
# Deploy application layer on top of core infra
```

## Troubleshooting

### Common Issues

1. **Environment Not Found**

   ```bash
   # Recreate environment
   ./scripts/project-switcher.sh resume project-name
   ```

2. **Branch Conflicts**

   ```bash
   # Stash changes before switching
   git stash
   ./scripts/project-switcher.sh switch other-project
   git stash pop  # When returning
   ```

3. **State File Issues**

   ```bash
   # Check project status
   ./scripts/project-switcher.sh status project-name

   # Recreate if needed
   ./scripts/project-switcher.sh destroy project-name
   ./scripts/project-switcher.sh start project-name
   ```

### Performance Tips

1. **Use SSH Config for Multiple Keys**

   ```bash
   # ~/.ssh/config
   Host dev-alice
     HostName your-server
     User ec2-user
     IdentityFile ~/.ssh/tf-playground-dev-alice.pem

   Host dev-bob
     HostName your-server
     User ec2-user
     IdentityFile ~/.ssh/tf-playground-dev-bob.pem
   ```

2. **Environment Variables**
   ```bash
   # Set in your shell profile
   export TF_VAR_developer=alice  # Default developer
   ```

## Benefits of This Approach

### ✅ **Maximum Productivity**

- No context switching overhead
- Maintain momentum across projects
- Fresh perspective when returning to projects

### ✅ **Project Isolation**

- Clean separation between projects
- No resource conflicts
- Independent development cycles

### ✅ **Cost Effective**

- Only run environments for active projects
- Automatic cleanup and cost management
- Small resources for development

### ✅ **Scalable**

- Easy to add new projects
- Can handle complex project dependencies
- Supports team growth if needed

### ✅ **Enterprise Ready**

- Same infrastructure as team development
- Proper resource tagging and management
- Security isolation between projects

This workflow transforms solo development from linear progress to parallel project management, maximizing productivity while maintaining cost discipline and project organization.

---

**NOTE: This document is archived. The concepts are advanced and may be overkill for basic development needs. Start with simple feature branches and grow into this complexity as needed.**
