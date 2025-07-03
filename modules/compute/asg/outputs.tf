output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.asg.id
}

output "launch_template_name" {
  description = "Name of the launch template"
  value       = aws_launch_template.asg.name
}

output "security_group_id" {
  description = "ID of the ASG security group"
  value       = var.security_group_id
}

output "iam_role_arn" {
  description = "ARN of the ASG IAM role"
  value       = aws_iam_role.asg.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.asg.name
}

output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = var.key_name != null ? var.key_name : aws_key_pair.asg[0].key_name
}

output "desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.desired_capacity
}

output "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.max_size
}

output "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.min_size
}

output "deployment_color" {
  description = "Deployment color of this ASG"
  value       = var.deployment_color
}

output "private_key" {
  description = "Private key for SSH access to instances"
  value       = var.key_name == null ? tls_private_key.asg[0].private_key_pem : null
  sensitive   = true
} 