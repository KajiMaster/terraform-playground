# AWS Load Balancer Controller Installation Action Plan

**Objective**: Fix ALB 504 Gateway Timeout by installing AWS Load Balancer Controller for EKS

## Prerequisites Check
Before starting, verify these components are ready:
- ✅ EKS cluster: `dev-eks-cluster` 
- ✅ kubectl access configured
- ✅ AWS credentials with EKS permissions
- ✅ Ingress resource exists: `kubernetes_ingress_v1.flask_app`

## Step-by-Step Installation

### Step 1: Install AWS Load Balancer Controller via kubectl

```bash
# Download and apply the controller YAML
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

# Create IAM policy for the controller
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json

# Create service account with IAM role (using eksctl or manual OIDC setup)
eksctl create iamserviceaccount \
  --cluster=dev-eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::123324351829:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install the controller using kubectl
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

# Download and install the controller deployment
curl -O https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.7.2/v2_7_2_full.yaml

# Edit the deployment to specify cluster name and region
sed -i 's/your-cluster-name/dev-eks-cluster/g' v2_7_2_full.yaml
sed -i 's/your-region/us-east-2/g' v2_7_2_full.yaml

kubectl apply -f v2_7_2_full.yaml
```

### Step 2: Alternative Installation via Helm (if kubectl method fails)

```bash
# Add the EKS charts repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install the controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=dev-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### Step 3: Verify Installation

```bash
# Check if controller pods are running
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify the ingress is now being processed
kubectl get ingress
kubectl describe ingress flask-app-ingress
```

### Step 4: Test ALB Connectivity

```bash
# Wait for ingress to get an address (may take 2-3 minutes)
kubectl get ingress -w

# Test the ALB endpoint
curl -v http://dev-alb-859214336.us-east-2.elb.amazonaws.com/health/simple

# Check target group health
aws elbv2 describe-target-health --target-group-arn [TARGET_GROUP_ARN]
```

## Expected Results

After successful installation:
1. **Controller pods**: Running in kube-system namespace
2. **Ingress**: Shows ALB address in `kubectl get ingress`
3. **ALB**: Automatically configured with EKS pods as targets
4. **Health checks**: Targets show as healthy
5. **Application**: Accessible via ALB URL

## Troubleshooting Steps

### If controller fails to start:
```bash
# Check service account permissions
kubectl describe serviceaccount aws-load-balancer-controller -n kube-system

# Check IAM role association
kubectl describe pod -l app.kubernetes.io/name=aws-load-balancer-controller -n kube-system
```

### If ingress doesn't get an address:
```bash
# Check ingress class annotation
kubectl get ingress flask-app-ingress -o yaml

# Verify controller is processing ingress
kubectl logs -n kube-system deployment/aws-load-balancer-controller | grep -i ingress
```

### If ALB still returns 504:
```bash
# Check target group registration
aws elbv2 describe-target-groups --names [TARGET_GROUP_NAME]

# Verify pod endpoints
kubectl get endpoints
```

## Rollback Plan

If installation fails:
```bash
# Remove controller
kubectl delete -f v2_7_2_full.yaml
# or
helm uninstall aws-load-balancer-controller -n kube-system

# Clean up IAM resources
aws iam delete-policy --policy-arn arn:aws:iam::123324351829:policy/AWSLoadBalancerControllerIAMPolicy
```

## Success Criteria

✅ **Controller installed**: Pods running in kube-system  
✅ **Ingress working**: ALB address visible in `kubectl get ingress`  
✅ **ALB healthy**: Target groups show healthy targets  
✅ **Application accessible**: `curl http://dev-alb-859214336.us-east-2.elb.amazonaws.com/health/simple` returns 200  

---
**Next Steps After Success**: Update Flask app service to LoadBalancer type if needed, test all endpoints, validate blue-green deployment readiness.