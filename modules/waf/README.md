# WAF Module

This module creates a centralized AWS WAF (Web Application Firewall) that can be shared across multiple environments to avoid daily recreation costs.

## Features

- **Rate Limiting**: Configurable rate limiting per IP address
- **AWS Managed Rules**: Common attack patterns, SQL injection, known bad inputs
- **IP Reputation**: Optional AWS IP reputation list integration
- **Custom Path Blocking**: Block specific URL paths
- **Logging**: Optional logging to S3 via Kinesis Firehose
- **Easy Enable/Disable**: Simple configuration to enable/disable without breaking other settings

## Usage

### In Global Environment

```hcl
module "waf" {
  source = "../../modules/waf"

  enable_waf           = true
  enable_logging       = true
  rate_limit           = 2000
  enable_ip_reputation = true
  blocked_paths        = "/admin,/internal,/debug"
  log_retention_days   = 7
}
```

### In Environment Root Modules

```hcl
# Application Load Balancer Module
module "loadbalancer" {
  source = "../../modules/loadbalancer"

  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnets    = module.networking.public_subnet_ids
  certificate_arn   = var.certificate_arn
  security_group_id = module.networking.alb_security_group_id
  waf_web_acl_arn   = data.terraform_remote_state.global.outputs.waf_web_acl_arn
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_waf | Enable WAF creation | `bool` | `true` | no |
| enable_logging | Enable WAF logging to S3 | `bool` | `true` | no |
| rate_limit | Rate limit for requests per IP (requests per 5 minutes) | `number` | `2000` | no |
| enable_ip_reputation | Enable AWS IP reputation list rule | `bool` | `true` | no |
| blocked_paths | Comma-separated list of paths to block (e.g., '/admin,/internal') | `string` | `null` | no |
| log_retention_days | Number of days to retain WAF logs | `number` | `7` | no |

## Outputs

| Name | Description |
|------|-------------|
| waf_web_acl_arn | ARN of the WAF Web ACL |
| waf_web_acl_id | ID of the WAF Web ACL |
| waf_web_acl_name | Name of the WAF Web ACL |
| waf_enabled | Whether WAF is enabled |
| waf_logging_enabled | Whether WAF logging is enabled |
| waf_log_bucket_name | Name of the S3 bucket storing WAF logs |

## WAF Rules

The module includes the following WAF rules:

1. **Rate Limiting**: Limits requests per IP address (configurable)
2. **Common Attack Patterns**: AWS managed rule for common web attacks
3. **SQL Injection**: AWS managed rule for SQL injection protection
4. **Known Bad Inputs**: AWS managed rule for known malicious inputs
5. **IP Reputation**: AWS managed rule for IP reputation (optional)
6. **Custom Path Blocking**: Blocks specific URL paths (optional)

## Logging

When logging is enabled, the module creates:
- S3 bucket for storing WAF logs
- Kinesis Firehose delivery stream
- IAM roles and policies for log delivery
- Lifecycle policy for log retention

## Easy WAF Control

Use the provided script to easily enable/disable WAF:

```bash
# Check WAF status
./scripts/waf-control.sh status

# Enable WAF
./scripts/waf-control.sh enable

# Disable WAF
./scripts/waf-control.sh disable
```

## Cost Optimization

- WAF is created in the global environment to avoid daily recreation costs
- Log retention is configurable to control storage costs
- Logging can be disabled entirely to reduce costs
- Rate limiting and rules are optimized for demo environments

## Security Considerations

- Default action is ALLOW (WAF rules are in COUNT mode)
- Rate limiting helps prevent DDoS attacks
- AWS managed rules provide protection against common attacks
- Custom path blocking can protect sensitive endpoints
- All rules include CloudWatch metrics for monitoring 