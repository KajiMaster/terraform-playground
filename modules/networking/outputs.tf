output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway (if created)"
  value       = var.create_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "nat_gateway_eip" {
  description = "The Elastic IP of the NAT Gateway (if created)"
  value       = var.create_nat_gateway ? aws_eip.nat[0].public_ip : null
}

output "webserver_security_group_id" {
  description = "The ID of the webserver security group"
  value       = aws_security_group.webserver.id
}

output "database_security_group_id" {
  description = "The ID of the database security group"
  value       = aws_security_group.database.id
}

output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = aws_route_table.private.id
} 