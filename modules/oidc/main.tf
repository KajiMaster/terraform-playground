terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# GitHub OIDC Provider (conditional to avoid conflicts)
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name        = "github-actions-oidc"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# Data source for existing OIDC provider (when not creating)
data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "github-actions-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "github-actions-role-${var.environment}"
    Environment = var.environment
    Project     = "tf-playground"
    ManagedBy   = "terraform"
  }
}

# IAM Policy for Terraform operations
resource "aws_iam_role_policy" "terraform_permissions" {
  name = "terraform-permissions-${var.environment}"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 permissions for state management
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket}",
          "arn:aws:s3:::${var.state_bucket}/*"
        ]
      },
      # DynamoDB permissions for state locking
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/${var.state_lock_table}"
      },
      # EC2 permissions for infrastructure management
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*"
        ]
        Resource = "*"
      },
      # RDS permissions
      {
        Effect = "Allow"
        Action = [
          "rds:*"
        ]
        Resource = "*"
      },
      # VPC permissions
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      # IAM permissions (limited to specific resources)
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:PassRole",
          "iam:CreateRole",
          "iam:CreatePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:DeleteRole",
          "iam:DeletePolicy",
          "iam:DeletePolicyVersion",
          "iam:CreatePolicyVersion",
          "iam:DeleteRolePolicy",
          "iam:PutRolePolicy",
          "iam:TagRole",
          "iam:TagPolicy",
          "iam:UntagRole",
          "iam:UntagPolicy",
          "iam:ListRolePolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:ListAttachedRolePolicies",
          "iam:GetRolePolicy",
          "iam:ListInstanceProfilesForRole",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile"
        ]
        Resource = [
          "arn:aws:iam::*:role/tf-playground-*",
          "arn:aws:iam::*:role/github-actions-*",
          "arn:aws:iam::*:role/staging-*",
          "arn:aws:iam::*:role/dev-*",
          "arn:aws:iam::*:role/prod-*",
          "arn:aws:iam::*:role/production-*",
          "arn:aws:iam::*:role/cleanup-logs-lambda-*",
          "arn:aws:iam::*:policy/tf-playground-*",
          "arn:aws:iam::*:policy/staging-*",
          "arn:aws:iam::*:policy/dev-*",
          "arn:aws:iam::*:policy/prod-*",
          "arn:aws:iam::*:policy/production-*",
          "arn:aws:iam::*:instance-profile/staging-*",
          "arn:aws:iam::*:instance-profile/dev-*",
          "arn:aws:iam::*:instance-profile/prod-*",
          "arn:aws:iam::*:instance-profile/production-*"
        ]
      },
      # OIDC Provider permissions (requires * resource)
      {
        Effect = "Allow"
        Action = [
          "iam:ListOpenIDConnectProviders",
          "iam:GetOpenIDConnectProvider"
        ]
        Resource = "*"
      },
      # KMS permissions for AWS managed keys (limited scope)
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      # Secrets Manager permissions
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:*"
        ]
        Resource = "*"
      },
      # SSM permissions for automation
      {
        Effect = "Allow"
        Action = [
          "ssm:*"
        ]
        Resource = "*"
      },
      # CloudWatch permissions for monitoring and alarms
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:*"
        ]
        Resource = "*"
      },
      # CloudWatch Logs permissions for Terraform and Lambda
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:CreateLogGroup",
          "logs:PutRetentionPolicy",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DeleteLogGroup",
          "logs:ListTagsForResource",
          "logs:TagResource",
          "logs:UntagResource"
        ]
        Resource = "*"
      },
      # Lambda permissions for function management
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunction",
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:DeleteFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:ListFunctions",
          "lambda:ListVersionsByFunction",
          "lambda:ListAliases",
          "lambda:DeleteFunctionConcurrency",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetRuntimeManagementConfig",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:ListTags"
        ]
        Resource = "*"
      },
      # WAF permissions for Web ACL management
      {
        Effect = "Allow"
        Action = [
          "wafv2:*"
        ]
        Resource = "*"
      },
      # Kinesis Firehose permissions for WAF logging
      {
        Effect = "Allow"
        Action = [
          "firehose:*"
        ]
        Resource = "*"
      },
      # ECS permissions for container orchestration
      {
        Effect = "Allow"
        Action = [
          "ecs:*"
        ]
        Resource = "*"
      },
      # ECR permissions for container registry
      {
        Effect = "Allow"
        Action = [
          "ecr:*"
        ]
        Resource = "*"
      }
    ]
  })
} 