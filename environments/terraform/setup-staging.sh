#!/bin/bash

echo "Setting up Terraform staging workspace..."

# Initialize with new backend configuration
echo "Initializing Terraform with new backend..."
terraform init -reconfigure

# Create staging workspace
echo "Creating staging workspace..."
terraform workspace new staging

# Switch to staging workspace
echo "Switching to staging workspace..."
terraform workspace select staging

echo "Staging workspace setup complete!"
echo "Current workspace: $(terraform workspace show)"
echo "Available workspaces:"
terraform workspace list 