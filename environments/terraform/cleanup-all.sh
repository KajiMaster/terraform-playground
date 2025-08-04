#!/bin/bash

# Nuclear cleanup script for tf-playground infrastructure
# This will delete ALL tf-playground resources in the correct order

set -e

echo "🚨 NUCLEAR CLEANUP: This will delete ALL tf-playground resources!"
echo "Resources found:"
echo "- EKS cluster: dev-eks-cluster"
echo "- ECS clusters: dev-ecs-cluster, staging-ecs-cluster"  
echo "- VPC: dev-vpc and all networking"
echo "- Security groups, IAM roles, log groups, S3 buckets"
echo ""
read -p "Are you absolutely sure? Type 'DELETE' to continue: " confirm

if [ "$confirm" != "DELETE" ]; then
    echo "Cancelled."
    exit 1
fi

echo "🧨 Starting nuclear cleanup..."

# Phase 1: EKS Cleanup
echo "Phase 1: Deleting EKS cluster..."
aws eks delete-cluster --name dev-eks-cluster --region us-east-2 || true
echo "Waiting for EKS cluster deletion..."
aws eks wait cluster-deleted --name dev-eks-cluster --region us-east-2 || true

# Phase 2: ECS Cleanup  
echo "Phase 2: Deleting ECS clusters..."
aws ecs delete-cluster --cluster dev-ecs-cluster --region us-east-2 || true
aws ecs delete-cluster --cluster staging-ecs-cluster --region us-east-2 || true

# Phase 3: Security Groups (delete non-default ones)
echo "Phase 3: Deleting security groups..."
aws ec2 describe-security-groups --region us-east-2 --filters "Name=group-name,Values=*tf-playground*,*dev-*,*staging-*,*production-*" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | xargs -n1 -I {} aws ec2 delete-security-group --group-id {} --region us-east-2 || true

# Phase 4: Networking Cleanup
echo "Phase 4: Deleting networking resources..."

# Delete subnets
aws ec2 describe-subnets --region us-east-2 --filters "Name=tag:Name,Values=*dev*,*staging*,*production*" --query 'Subnets[].SubnetId' --output text | xargs -n1 -I {} aws ec2 delete-subnet --subnet-id {} --region us-east-2 || true

# Delete route tables (non-main)
aws ec2 describe-route-tables --region us-east-2 --filters "Name=tag:Name,Values=*dev*,*staging*,*production*" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text | xargs -n1 -I {} aws ec2 delete-route-table --route-table-id {} --region us-east-2 || true

# Delete VPC
VPC_ID=$(aws ec2 describe-vpcs --region us-east-2 --filters "Name=tag:Name,Values=dev-vpc" --query 'Vpcs[0].VpcId' --output text)
if [ "$VPC_ID" != "None" ] && [ "$VPC_ID" != "" ]; then
    aws ec2 delete-vpc --vpc-id $VPC_ID --region us-east-2 || true
fi

# Phase 5: Supporting Resources
echo "Phase 5: Cleaning up supporting resources..."

# Delete CloudWatch Log Groups
aws logs describe-log-groups --region us-east-2 --log-group-name-prefix "/aws/application/tf-playground" --query 'logGroups[].logGroupName' --output text | xargs -n1 -I {} aws logs delete-log-group --log-group-name {} --region us-east-2 || true
aws logs describe-log-groups --region us-east-2 --log-group-name-prefix "/aws/cloudwatch/alarms/tf-playground" --query 'logGroups[].logGroupName' --output text | xargs -n1 -I {} aws logs delete-log-group --log-group-name {} --region us-east-2 || true
aws logs describe-log-groups --region us-east-2 --log-group-name-prefix "/aws/ec2/tf-playground" --query 'logGroups[].logGroupName' --output text | xargs -n1 -I {} aws logs delete-log-group --log-group-name {} --region us-east-2 || true
aws logs describe-log-groups --region us-east-2 --log-group-name-prefix "/aws/ecs/containerinsights" --query 'logGroups[].logGroupName' --output text | xargs -n1 -I {} aws logs delete-log-group --log-group-name {} --region us-east-2 || true

# Delete IAM roles (check if they're not in use first)
echo "Deleting IAM roles..."
aws iam delete-role --role-name dev-ecs-task-execution-role --region us-east-2 || true
aws iam delete-role --role-name dev-ecs-task-role --region us-east-2 || true  
aws iam delete-role --role-name dev-eks-cluster-cluster-role --region us-east-2 || true
aws iam delete-role --role-name dev-eks-cluster-node-group-role --region us-east-2 || true

echo ""
echo "✅ Nuclear cleanup complete!"
echo ""
echo "⚠️  MANUAL CLEANUP NEEDED:"
echo "1. S3 Buckets (need to be emptied first):"
echo "   - tf-playground-state-vexus"
echo "   - tf-playground-waf-logs-9p5le35r"
echo "2. ECS Task Definitions (if you want them gone)"
echo ""
echo "Run this to empty and delete S3 buckets:"
echo "aws s3 rm s3://tf-playground-state-vexus --recursive"
echo "aws s3 rb s3://tf-playground-state-vexus"
echo "aws s3 rm s3://tf-playground-waf-logs-9p5le35r --recursive" 
echo "aws s3 rb s3://tf-playground-waf-logs-9p5le35r"