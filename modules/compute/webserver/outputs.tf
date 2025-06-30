output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.webserver.id
}

output "public_ip" {
  description = "Public IP address of the web server"
  value       = aws_eip.webserver.public_ip
}

output "security_group_id" {
  description = "ID of the web server security group"
  value       = var.security_group_id
}

output "instance_private_ip" {
  description = "Private IP address of the web server"
  value       = aws_instance.webserver.private_ip
} 