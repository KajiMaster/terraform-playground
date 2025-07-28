# Flask App - Containerized

This is the containerized version of the Flask application for the ECS Fargate migration project.

## 🏗️ Architecture

### Key Changes from EC2 Version:
- **Parameter Store**: Uses AWS Parameter Store instead of Secrets Manager for cost optimization
- **Container ID**: Uses `HOSTNAME` environment variable for container identification
- **Environment Variables**: All configuration via environment variables
- **Health Checks**: Built-in Docker health checks
- **Non-root User**: Runs as non-root user for security

### Environment Variables:
- `DB_HOST`: Database host (default: localhost)
- `DB_USER`: Database username (default: tfplayground_user)
- `DB_NAME`: Database name (default: tfplayground)
- `DEPLOYMENT_COLOR`: Deployment color for blue-green (default: unknown)
- `AWS_REGION`: AWS region for Parameter Store (default: us-east-2)

## 🚀 Local Development

### Prerequisites:
- Docker and Docker Compose installed
- `curl` and `jq` for testing
- AWS CLI configured (for Parameter Store testing)

### Quick Start:
```bash
# Build and test locally with MySQL
./test-local.sh

# Test Parameter Store integration
./test-parameter-store.sh

# Or manually:
docker compose up -d
curl http://localhost:8080/health/simple
```

### Manual Testing:
```bash
# Build the image
docker-compose build

# Start services
docker-compose up -d

# Test endpoints
curl http://localhost:8080/health/simple
curl http://localhost:8080/
curl http://localhost:8080/info

# View logs
docker-compose logs -f flask-app

# Stop services
docker-compose down
```

## 📊 Endpoints

### Health Checks:
- `/health/simple` - Simple health check for load balancers
- `/health` - Comprehensive health check with all system metrics

### Application:
- `/` - Main application endpoint (returns contacts)
- `/info` - Container and system information
- `/deployment/validate` - Deployment validation endpoint

### Chaos Testing:
- `/error/500` - Generate 500 error
- `/error/slow` - Generate slow response
- `/error/db` - Generate database error

## 🔧 Docker Commands

### Build Image:
```bash
docker build -t flask-app .
```

### Run Container:
```bash
docker run -p 8080:8080 \
  -e DB_HOST=your-db-host \
  -e DB_USER=your-db-user \
  -e DB_NAME=your-db-name \
  -e DEPLOYMENT_COLOR=blue \
  flask-app
```

### Interactive Shell:
```bash
docker run -it --rm flask-app /bin/bash
```

## 🏗️ ECS Deployment

This container is designed to be deployed to ECS Fargate with:

1. **Task Definition**: CPU/memory allocation and environment variables
2. **Service**: Auto-scaling and load balancer integration
3. **IAM Role**: Access to Parameter Store and CloudWatch
4. **Security Groups**: Network access control

### ECS Environment Variables:
```json
{
  "DB_HOST": "your-rds-endpoint",
  "DB_USER": "tfplayground_user",
  "DB_NAME": "tfplayground",
  "DEPLOYMENT_COLOR": "blue",
  "AWS_REGION": "us-east-2"
}
```

**Note**: The container will automatically retrieve `DB_PASSWORD` from Parameter Store using the IAM role.

## 🔒 Security

- **Non-root User**: Container runs as `app` user
- **Parameter Store**: Secure credential management
- **Health Checks**: Built-in container health monitoring
- **Logging**: Structured logging to stdout for CloudWatch

## 📈 Monitoring

- **Health Checks**: Docker and application-level health checks
- **Logging**: Structured JSON logging to stdout
- **Metrics**: System metrics via `/info` endpoint
- **Chaos Testing**: Built-in endpoints for testing failure scenarios

## 🚀 Next Steps

1. **Local Testing**: Verify container works locally
2. **ECR Repository**: Create ECR repository in staging environment
3. **ECS Module**: Create ECS infrastructure module
4. **CI/CD Integration**: Update GitHub Actions for container builds
5. **Migration**: Gradually migrate from ASG to ECS 