key_name = "tf-playground-staging"

# WAF Configuration
environment_waf_use = false 

# ECS Configuration
enable_ecs = true

# Migration Control
# Set to true to disable ASG and use ECS only
disable_asg = true

# ECS Service Configuration
# Start with blue service only, green will be used for deployments
blue_ecs_desired_count = 1
green_ecs_desired_count = 0