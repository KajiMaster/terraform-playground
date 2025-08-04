#!/bin/bash

# Targeted cleanup script for environment-specific resources only
# PRESERVES: Global infrastructure (OIDC, ECR, WAF, state bucket, global log groups)
# DELETES: Dev/staging/production networking, compute, and app resources

set -e

echo "🎯 TARGETED CLEANUP: Environment-specific resources only"
echo ""
echo "WILL DELETE:"
echo "- EKS cluster: dev-eks-cluster"
echo "- ECS clusters: dev-ecs-cluster, staging-ecs-cluster"  
echo "- VPC: dev-vpc and all networking (subnets, route tables, security groups)"
echo "- Environment-specific IAM roles"
echo "- Environment-specific log groups"
echo ""
echo "WILL PRESERVE:"
echo "- Global OIDC provider"
echo "- ECR repository" 
echo "- WAF and global log groups"
echo "- S3 state bucket: tf-playground-state-vexus"
echo "- Global infrastructure"
echo ""
read -p "Continue with targeted cleanup? Type 'YES' to proceed: " confirm

if [ "$confirm" != "YES" ]; then
    echo "Cancelled."
    exit 1
fi

echo "🧹 Starting targeted environment cleanup..."

# Phase 1: EKS Cleanup
echo "Phase 1: Deleting EKS cluster..."
if aws eks describe-cluster --name dev-eks-cluster --region us-east-2 >/dev/null 2>&1; then
    echo "Deleting EKS cluster: dev-eks-cluster"
    aws eks delete-cluster --name dev-eks-cluster --region us-east-2
    echo "Waiting for EKS cluster deletion..."
    aws eks wait cluster-deleted --name dev-eks-cluster --region us-east-2 || echo "EKS deletion timeout - continuing..."
else
    echo "EKS cluster not found or already deleted"
fi

# Phase 2: ECS Cleanup  
echo "Phase 2: Deleting ECS clusters..."
aws ecs delete-cluster --cluster dev-ecs-cluster --region us-east-2 2>/dev/null || echo "dev-ecs-cluster not found"
aws ecs delete-cluster --cluster staging-ecs-cluster --region us-east-2 2>/dev/null || echo "staging-ecs-cluster not found"

# Phase 3: Security Groups (environment-specific only)
echo "Phase 3: Deleting environment-specific security groups..."
# Get all security groups with environment prefixes (dev-, staging-, production-)
for env in dev staging production; do
    echo "Deleting $env security groups..."
    aws ec2 describe-security-groups --region us-east-2 \
        --filters "Name=group-name,Values=${env}-*" \
        --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
        --output text | tr '\t' '\n' | while read sg_id; do
        if [ ! -z "$sg_id" ] && [ "$sg_id" != "None" ]; then
            echo "Deleting security group: $sg_id"
            aws ec2 delete-security-group --group-id "$sg_id" --region us-east-2 2>/dev/null || echo "Failed to delete $sg_id (may have dependencies)"
        fi
    done
done

# Phase 4: Networking Cleanup (environment-specific VPCs)
echo "Phase 4: Deleting environment-specific networking..."

for env in dev staging production; do
    echo "Cleaning up $env networking..."
    
    # Get VPC ID for this environment
    VPC_ID=$(aws ec2 describe-vpcs --region us-east-2 \
        --filters "Name=tag:Name,Values=${env}-vpc" \
        --query 'Vpcs[0].VpcId' --output text)
    
    if [ "$VPC_ID" != "None" ] && [ "$VPC_ID" != "" ]; then
        echo "Found VPC for $env: $VPC_ID"
        
        # Delete subnets in this VPC
        aws ec2 describe-subnets --region us-east-2 \
            --filters "Name=vpc-id,Values=$VPC_ID" \
            --query 'Subnets[].SubnetId' --output text | tr '\t' '\n' | while read subnet_id; do
            if [ ! -z "$subnet_id" ] && [ "$subnet_id" != "None" ]; then
                echo "Deleting subnet: $subnet_id"
                aws ec2 delete-subnet --subnet-id "$subnet_id" --region us-east-2 2>/dev/null || echo "Failed to delete subnet $subnet_id"
            fi
        done
        
        # Delete route tables (non-main) in this VPC
        aws ec2 describe-route-tables --region us-east-2 \
            --filters "Name=vpc-id,Values=$VPC_ID" \
            --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' \
            --output text | tr '\t' '\n' | while read rt_id; do
            if [ ! -z "$rt_id" ] && [ "$rt_id" != "None" ]; then
                echo "Deleting route table: $rt_id"
                aws ec2 delete-route-table --route-table-id "$rt_id" --region us-east-2 2>/dev/null || echo "Failed to delete route table $rt_id"
            fi
        done
        
        # Delete remaining security groups in this VPC (retry after dependencies removed)
        sleep 5
        aws ec2 describe-security-groups --region us-east-2 \
            --filters "Name=vpc-id,Values=$VPC_ID" \
            --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
            --output text | tr '\t' '\n' | while read sg_id; do
            if [ ! -z "$sg_id" ] && [ "$sg_id" != "None" ]; then
                echo "Deleting remaining security group: $sg_id"
                aws ec2 delete-security-group --group-id "$sg_id" --region us-east-2 2>/dev/null || echo "Failed to delete $sg_id"
            fi
        done
        
        # Delete VPC
        echo "Deleting VPC: $VPC_ID"
        aws ec2 delete-vpc --vpc-id "$VPC_ID" --region us-east-2 2>/dev/null || echo "Failed to delete VPC $VPC_ID"
    else
        echo "No VPC found for $env"
    fi
done

# Phase 5: Environment-specific IAM roles
echo "Phase 5: Deleting environment-specific IAM roles..."
for role in dev-ecs-task-execution-role dev-ecs-task-role dev-eks-cluster-cluster-role dev-eks-cluster-node-group-role; do
    echo "Checking role: $role"
    if aws iam get-role --role-name "$role" >/dev/null 2>&1; then
        # Detach policies first
        aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[].PolicyArn' --output text | tr '\t' '\n' | while read policy_arn; do
            if [ ! -z "$policy_arn" ] && [ "$policy_arn" != "None" ]; then
                echo "Detaching policy $policy_arn from $role"
                aws iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn" 2>/dev/null || true
            fi
        done
        
        # Delete inline policies
        aws iam list-role-policies --role-name "$role" --query 'PolicyNames[]' --output text | tr '\t' '\n' | while read policy_name; do
            if [ ! -z "$policy_name" ] && [ "$policy_name" != "None" ]; then
                echo "Deleting inline policy $policy_name from $role"
                aws iam delete-role-policy --role-name "$role" --policy-name "$policy_name" 2>/dev/null || true
            fi
        done
        
        echo "Deleting role: $role"
        aws iam delete-role --role-name "$role" 2>/dev/null || echo "Failed to delete role $role"
    else
        echo "Role $role not found"
    fi
done

# Phase 6: Environment-specific CloudWatch Log Groups (PRESERVE GLOBAL ONES)
echo "Phase 6: Deleting environment-specific log groups..."
# Only delete log groups that are clearly environment-specific
aws logs describe-log-groups --region us-east-2 --query 'logGroups[?contains(logGroupName, `/dev/`) || contains(logGroupName, `/staging/`) || contains(logGroupName, `/production/`) || contains(logGroupName, `dev-ecs-cluster`) || contains(logGroupName, `staging-ecs-cluster`)].logGroupName' --output text | tr '\t' '\n' | while read log_group; do
    if [ ! -z "$log_group" ] && [ "$log_group" != "None" ]; then
        echo "Deleting log group: $log_group"
        aws logs delete-log-group --log-group-name "$log_group" --region us-east-2 2>/dev/null || echo "Failed to delete log group $log_group"
    fi
done

echo ""
echo "✅ Targeted environment cleanup complete!"
echo ""
echo "🔒 PRESERVED (as requested):"
echo "- Global OIDC provider"
echo "- ECR repository"
echo "- WAF web ACL and global log groups"
echo "- S3 state bucket: tf-playground-state-vexus"
echo "- Global CloudWatch log groups"
echo ""
echo "🗑️ DELETED:"
echo "- All dev/staging/production VPCs and networking"
echo "- EKS and ECS clusters"
echo "- Environment-specific IAM roles"
echo "- Environment-specific log groups"
echo ""
echo "🚀 Ready for fresh environment deployment!"