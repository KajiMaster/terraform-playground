# Blue-Green Failover Quick Reference

## 🚀 Quick Commands

### Manual Failover Commands

#### Blue to Green Failover
```bash
# Switch traffic to green
aws elbv2 modify-listener \
  --listener-arn $(terraform output -raw http_listener_arn) \
  --default-actions Type=forward,TargetGroupArn=$(terraform output -raw green_target_group_arn) \
  --region us-east-2

# Wait for health checks
sleep 15

# Verify switch
curl -s $(terraform output -raw application_url) | jq .deployment_color
# Expected: "green"
```

#### Green to Blue Rollback
```bash
# Switch traffic back to blue
aws elbv2 modify-listener \
  --listener-arn $(terraform output -raw http_listener_arn) \
  --default-actions Type=forward,TargetGroupArn=$(terraform output -raw blue_target_group_arn) \
  --region us-east-2

# Wait for health checks
sleep 15

# Verify rollback
curl -s $(terraform output -raw application_url) | jq .deployment_color
# Expected: "blue"
```

### Automated Testing

#### Run Complete Failover Test
```bash
./scripts/blue-green-failover-test.sh dev us-east-2
```

#### Run Individual Tests
```bash
# Blue to Green only
./scripts/test-blue-to-green.sh dev us-east-2

# Green to Blue only
./scripts/test-green-to-blue.sh dev us-east-2

# Health checks only
./scripts/test-health-checks.sh
```

## 🔍 Health Check Commands

### Check Target Group Health
```bash
# Blue target group
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw blue_target_group_arn) \
  --region us-east-2

# Green target group
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw green_target_group_arn) \
  --region us-east-2
```

### Check Application Health
```bash
# Health endpoint
curl $(terraform output -raw health_check_url)

# Main application
curl $(terraform output -raw application_url) | jq .
```

### Check Current Traffic Flow
```bash
# Which target group is receiving traffic
aws elbv2 describe-listeners \
  --listener-arns $(terraform output -raw http_listener_arn) \
  --region us-east-2 \
  --query 'Listeners[0].DefaultActions[0].TargetGroupArn'
```

## 📋 Pre-Failover Checklist

- [ ] Both environments are healthy
- [ ] Database connectivity confirmed
- [ ] Application responding on both endpoints
- [ ] No active deployments in progress
- [ ] Monitoring alerts configured
- [ ] Rollback plan ready

## ⚠️ Troubleshooting

### 502 Bad Gateway
1. Wait 15 seconds after traffic switch
2. Check target group health
3. Verify application is running on target instances
4. Check security group rules
5. Review application logs

### Health Check Failures
1. Verify `/health` endpoint returns 200
2. Check database connectivity
3. Ensure application is listening on port 8080
4. Review instance logs

### Traffic Not Switching
1. Verify listener ARN is correct
2. Check target group ARN
3. Confirm AWS CLI permissions
4. Wait for DNS propagation

## 🎯 Success Criteria

- ✅ Zero downtime during switch
- ✅ Application responds with correct deployment color
- ✅ Database connectivity maintained
- ✅ No 5xx errors
- ✅ Health checks pass on target environment

## 📞 Emergency Contacts

- **Primary**: DevOps Team
- **Secondary**: Infrastructure Team
- **Escalation**: System Administrator

---

**Last Updated**: June 26, 2025
**Environment**: Dev (Tested and Verified)
**Status**: ✅ Production Ready 