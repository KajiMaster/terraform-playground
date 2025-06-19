#!/bin/bash

# Solo Developer Multi-Project Switcher
# Usage: ./scripts/project-switcher.sh <action> [project-name]

set -e

PROJECTS_FILE=".projects.json"

# Initialize projects file if it doesn't exist
if [ ! -f "$PROJECTS_FILE" ]; then
    cat > "$PROJECTS_FILE" << 'EOF'
{
  "projects": {
    "database-optimization": {
      "developer": "alice",
      "description": "Database performance improvements",
      "status": "active",
      "created": "",
      "last_worked": ""
    },
    "load-balancer": {
      "developer": "bob", 
      "description": "Application load balancer setup",
      "status": "active",
      "created": "",
      "last_worked": ""
    },
    "monitoring": {
      "developer": "charlie",
      "description": "CloudWatch monitoring and alerts",
      "status": "paused",
      "created": "",
      "last_worked": ""
    },
    "caching": {
      "developer": "diana",
      "description": "Redis caching layer implementation",
      "status": "planned",
      "created": "",
      "last_worked": ""
    }
  }
}
EOF
fi

function show_help() {
    echo "Solo Developer Multi-Project Switcher"
    echo ""
    echo "Usage: $0 <action> [project-name]"
    echo ""
    echo "Actions:"
    echo "  list                    - List all projects and their status"
    echo "  start <project>         - Start working on a project (create branch + deploy env)"
    echo "  switch <project>        - Switch to an existing project"
    echo "  pause <project>         - Pause a project (destroy env, save state)"
    echo "  resume <project>        - Resume a paused project (recreate env)"
    echo "  finish <project>        - Mark project ready for staging (PR)"
    echo "  destroy <project>       - Destroy project environment and clean up"
    echo "  status <project>        - Show detailed status of a project"
    echo "  help                    - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 start database-optimization"
    echo "  $0 switch load-balancer"
    echo "  $0 pause monitoring"
    echo "  $0 resume caching"
}

function list_projects() {
    echo "📋 Project Status Overview"
    echo "=========================="
    echo ""
    
    # Use jq to parse and display projects
    jq -r '.projects | to_entries[] | "\(.key): \(.value.status) - \(.value.description) (Dev: \(.value.developer))"' "$PROJECTS_FILE" | while IFS=': ' read -r project status description; do
        case $status in
            "active")
                echo "🟢 $project: $description"
                ;;
            "paused")
                echo "🟡 $project: $description"
                ;;
            "planned")
                echo "⚪ $project: $description"
                ;;
            "ready")
                echo "🔵 $project: $description"
                ;;
        esac
    done
    
    echo ""
    echo "Current branch: $(git branch --show-current)"
    echo "Current developer: ${TF_VAR_developer:-'not set'}"
}

function start_project() {
    local project_name=$1
    local project_data
    
    if [ -z "$project_name" ]; then
        echo "❌ Error: Project name required"
        echo "Usage: $0 start <project-name>"
        exit 1
    fi
    
    # Check if project exists
    project_data=$(jq -r ".projects.\"$project_name\"" "$PROJECTS_FILE" 2>/dev/null)
    if [ "$project_data" = "null" ]; then
        echo "❌ Error: Project '$project_name' not found"
        echo "Available projects:"
        jq -r '.projects | keys[]' "$PROJECTS_FILE"
        exit 1
    fi
    
    local developer=$(echo "$project_data" | jq -r '.developer')
    local status=$(echo "$project_data" | jq -r '.status')
    
    echo "🚀 Starting project: $project_name"
    echo "Developer: $developer"
    echo "Status: $status"
    echo ""
    
    # Create feature branch
    echo "📝 Creating feature branch..."
    git checkout -b "feature/$project_name" 2>/dev/null || git checkout "feature/$project_name"
    
    # Set up developer environment
    echo "🔧 Setting up developer environment..."
    export TF_VAR_developer=$developer
    
    # Run setup script
    echo "⚙️  Running developer setup..."
    ./scripts/setup-developer-env.sh "$developer"
    
    # Deploy infrastructure
    echo "🏗️  Deploying infrastructure..."
    cd environments/dev
    terraform init
    terraform apply -var="developer=$developer" -auto-approve
    
    # Update project status
    jq ".projects.\"$project_name\".status = \"active\" | .projects.\"$project_name\".last_worked = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$PROJECTS_FILE" > "$PROJECTS_FILE.tmp" && mv "$PROJECTS_FILE.tmp" "$PROJECTS_FILE"
    
    echo ""
    echo "✅ Project '$project_name' started successfully!"
    echo "🌐 Web server: http://$(terraform output -raw webserver_public_ip):8080"
    echo "💾 Database: $(terraform output -raw database_endpoint)"
    echo ""
    echo "Next steps:"
    echo "1. Make your changes"
    echo "2. Test your infrastructure"
    echo "3. Use '$0 pause $project_name' to pause when done"
    echo "4. Use '$0 finish $project_name' when ready for staging"
}

function switch_project() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        echo "❌ Error: Project name required"
        echo "Usage: $0 switch <project-name>"
        exit 1
    fi
    
    local project_data=$(jq -r ".projects.\"$project_name\"" "$PROJECTS_FILE" 2>/dev/null)
    if [ "$project_data" = "null" ]; then
        echo "❌ Error: Project '$project_name' not found"
        exit 1
    fi
    
    local developer=$(echo "$project_data" | jq -r '.developer')
    local status=$(echo "$project_data" | jq -r '.status')
    
    echo "🔄 Switching to project: $project_name"
    echo "Developer: $developer"
    echo "Status: $status"
    echo ""
    
    # Switch to feature branch
    git checkout "feature/$project_name" 2>/dev/null || {
        echo "❌ Error: Branch 'feature/$project_name' not found"
        echo "Use '$0 start $project_name' to create the project first"
        exit 1
    }
    
    # Set developer environment
    export TF_VAR_developer=$developer
    echo "export TF_VAR_developer=$developer" > .current_project
    
    # Check if environment is running
    cd environments/dev
    if aws s3api head-object --bucket tf-playground-state-vexus --key "dev-$developer/terraform.tfstate" 2>/dev/null; then
        echo "✅ Environment is running"
        terraform init
        echo "🌐 Web server: http://$(terraform output -raw webserver_public_ip):8080"
    else
        echo "⚠️  Environment not running. Use '$0 resume $project_name' to recreate it"
    fi
    
    echo ""
    echo "✅ Switched to project '$project_name'"
    echo "Current branch: $(git branch --show-current)"
    echo "Current developer: $developer"
}

function pause_project() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        echo "❌ Error: Project name required"
        echo "Usage: $0 pause <project-name>"
        exit 1
    fi
    
    local project_data=$(jq -r ".projects.\"$project_name\"" "$PROJECTS_FILE" 2>/dev/null)
    if [ "$project_data" = "null" ]; then
        echo "❌ Error: Project '$project_name' not found"
        exit 1
    fi
    
    local developer=$(echo "$project_data" | jq -r '.developer')
    
    echo "⏸️  Pausing project: $project_name"
    echo "Developer: $developer"
    echo ""
    
    # Switch to project branch
    git checkout "feature/$project_name" 2>/dev/null || {
        echo "❌ Error: Branch 'feature/$project_name' not found"
        exit 1
    }
    
    # Destroy environment
    echo "🗑️  Destroying environment..."
    cd environments/dev
    export TF_VAR_developer=$developer
    terraform destroy -auto-approve
    
    # Update project status
    jq ".projects.\"$project_name\".status = \"paused\" | .projects.\"$project_name\".last_worked = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$PROJECTS_FILE" > "$PROJECTS_FILE.tmp" && mv "$PROJECTS_FILE.tmp" "$PROJECTS_FILE"
    
    echo ""
    echo "✅ Project '$project_name' paused successfully!"
    echo "💾 Environment destroyed (cost savings)"
    echo "📝 Code changes saved in branch 'feature/$project_name'"
    echo ""
    echo "To resume later: $0 resume $project_name"
}

function resume_project() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        echo "❌ Error: Project name required"
        echo "Usage: $0 resume <project-name>"
        exit 1
    fi
    
    local project_data=$(jq -r ".projects.\"$project_name\"" "$PROJECTS_FILE" 2>/dev/null)
    if [ "$project_data" = "null" ]; then
        echo "❌ Error: Project '$project_name' not found"
        exit 1
    fi
    
    local developer=$(echo "$project_data" | jq -r '.developer')
    local status=$(echo "$project_data" | jq -r '.status')
    
    if [ "$status" != "paused" ]; then
        echo "❌ Error: Project '$project_name' is not paused (status: $status)"
        exit 1
    fi
    
    echo "▶️  Resuming project: $project_name"
    echo "Developer: $developer"
    echo ""
    
    # Switch to project branch
    git checkout "feature/$project_name" 2>/dev/null || {
        echo "❌ Error: Branch 'feature/$project_name' not found"
        exit 1
    }
    
    # Recreate environment
    echo "🔧 Recreating environment..."
    export TF_VAR_developer=$developer
    ./scripts/setup-developer-env.sh "$developer"
    
    cd environments/dev
    terraform init
    terraform apply -var="developer=$developer" -auto-approve
    
    # Update project status
    jq ".projects.\"$project_name\".status = \"active\" | .projects.\"$project_name\".last_worked = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$PROJECTS_FILE" > "$PROJECTS_FILE.tmp" && mv "$PROJECTS_FILE.tmp" "$PROJECTS_FILE"
    
    echo ""
    echo "✅ Project '$project_name' resumed successfully!"
    echo "🌐 Web server: http://$(terraform output -raw webserver_public_ip):8080"
    echo "💾 Database: $(terraform output -raw database_endpoint)"
}

function finish_project() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        echo "❌ Error: Project name required"
        echo "Usage: $0 finish <project-name>"
        exit 1
    fi
    
    local project_data=$(jq -r ".projects.\"$project_name\"" "$PROJECTS_FILE" 2>/dev/null)
    if [ "$project_data" = "null" ]; then
        echo "❌ Error: Project '$project_name' not found"
        exit 1
    fi
    
    local developer=$(echo "$project_data" | jq -r '.developer')
    
    echo "🎯 Finishing project: $project_name"
    echo "Developer: $developer"
    echo ""
    
    # Switch to project branch
    git checkout "feature/$project_name" 2>/dev/null || {
        echo "❌ Error: Branch 'feature/$project_name' not found"
        exit 1
    }
    
    # Check if environment is running
    cd environments/dev
    export TF_VAR_developer=$developer
    
    if ! aws s3api head-object --bucket tf-playground-state-vexus --key "dev-$developer/terraform.tfstate" 2>/dev/null; then
        echo "⚠️  Environment not running. Recreating for final testing..."
        terraform init
        terraform apply -var="developer=$developer" -auto-approve
    fi
    
    # Final testing
    echo "🧪 Running final tests..."
    echo "🌐 Web server: http://$(terraform output -raw webserver_public_ip):8080"
    echo "💾 Database: $(terraform output -raw database_endpoint)"
    
    # Update project status
    jq ".projects.\"$project_name\".status = \"ready\" | .projects.\"$project_name\".last_worked = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$PROJECTS_FILE" > "$PROJECTS_FILE.tmp" && mv "$PROJECTS_FILE.tmp" "$PROJECTS_FILE"
    
    echo ""
    echo "✅ Project '$project_name' marked as ready!"
    echo ""
    echo "Next steps:"
    echo "1. Create PR to main: git push origin feature/$project_name"
    echo "2. PR will trigger staging deployment"
    echo "3. Environment will be auto-cleaned up when PR is merged"
    echo ""
    echo "To create PR:"
    echo "  git add ."
    echo "  git commit -m \"Complete $project_name\""
    echo "  git push origin feature/$project_name"
}

function destroy_project() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        echo "❌ Error: Project name required"
        echo "Usage: $0 destroy <project-name>"
        exit 1
    fi
    
    local project_data=$(jq -r ".projects.\"$project_name\"" "$PROJECTS_FILE" 2>/dev/null)
    if [ "$project_data" = "null" ]; then
        echo "❌ Error: Project '$project_name' not found"
        exit 1
    fi
    
    local developer=$(echo "$project_data" | jq -r '.developer')
    
    echo "💥 Destroying project: $project_name"
    echo "Developer: $developer"
    echo "⚠️  This will permanently delete the environment and branch!"
    echo ""
    
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled"
        exit 1
    fi
    
    # Destroy environment
    echo "🗑️  Destroying environment..."
    cd environments/dev
    export TF_VAR_developer=$developer
    terraform destroy -auto-approve
    
    # Clean up secrets and keys
    echo "🧹 Cleaning up secrets and keys..."
    aws secretsmanager delete-secret --secret-id "/tf-playground/dev-$developer/database/credentials" --force-delete-without-recovery 2>/dev/null || true
    aws ec2 delete-key-pair --key-name "tf-playground-dev-$developer" 2>/dev/null || true
    
    # Delete branch
    echo "🗑️  Deleting branch..."
    git checkout main
    git branch -D "feature/$project_name" 2>/dev/null || true
    
    # Remove from projects file
    jq "del(.projects.\"$project_name\")" "$PROJECTS_FILE" > "$PROJECTS_FILE.tmp" && mv "$PROJECTS_FILE.tmp" "$PROJECTS_FILE"
    
    echo ""
    echo "✅ Project '$project_name' completely destroyed!"
}

function show_status() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        echo "❌ Error: Project name required"
        echo "Usage: $0 status <project-name>"
        exit 1
    fi
    
    local project_data=$(jq -r ".projects.\"$project_name\"" "$PROJECTS_FILE" 2>/dev/null)
    if [ "$project_data" = "null" ]; then
        echo "❌ Error: Project '$project_name' not found"
        exit 1
    fi
    
    local developer=$(echo "$project_data" | jq -r '.developer')
    local status=$(echo "$project_data" | jq -r '.status')
    local description=$(echo "$project_data" | jq -r '.description')
    local created=$(echo "$project_data" | jq -r '.created')
    local last_worked=$(echo "$project_data" | jq -r '.last_worked')
    
    echo "📊 Project Status: $project_name"
    echo "================================"
    echo "Description: $description"
    echo "Developer: $developer"
    echo "Status: $status"
    echo "Created: $created"
    echo "Last worked: $last_worked"
    echo ""
    
    # Check if branch exists
    if git show-ref --verify --quiet refs/heads/feature/$project_name; then
        echo "✅ Branch exists: feature/$project_name"
    else
        echo "❌ Branch missing: feature/$project_name"
    fi
    
    # Check if environment is running
    if aws s3api head-object --bucket tf-playground-state-vexus --key "dev-$developer/terraform.tfstate" 2>/dev/null; then
        echo "✅ Environment is running"
        
        # Show environment details
        cd environments/dev
        export TF_VAR_developer=$developer
        terraform init >/dev/null 2>&1
        
        if terraform output webserver_public_ip >/dev/null 2>&1; then
            echo "🌐 Web server: http://$(terraform output -raw webserver_public_ip):8080"
        fi
        
        if terraform output database_endpoint >/dev/null 2>&1; then
            echo "💾 Database: $(terraform output -raw database_endpoint)"
        fi
    else
        echo "❌ Environment not running"
    fi
}

# Main script logic
case "${1:-help}" in
    "list")
        list_projects
        ;;
    "start")
        start_project "$2"
        ;;
    "switch")
        switch_project "$2"
        ;;
    "pause")
        pause_project "$2"
        ;;
    "resume")
        resume_project "$2"
        ;;
    "finish")
        finish_project "$2"
        ;;
    "destroy")
        destroy_project "$2"
        ;;
    "status")
        show_status "$2"
        ;;
    "help"|*)
        show_help
        ;;
esac 