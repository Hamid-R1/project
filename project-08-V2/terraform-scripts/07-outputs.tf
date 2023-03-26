# public-ip of bastion-server
output "public-ip-bastion-server" {
  value = aws_instance.wp-bastion-server.public_ip
}

# private-ip of app-server-1
output "private-ip-app-server-1" {
  value = aws_instance.wp-app-server-1.private_ip
}

# private-ip of app-server-2
output "private-ip-app-server-2" {
  value = aws_instance.wp-app-server-2.private_ip
}

# rds-endpoint
output "rds_address" {
  value = aws_db_instance.db_instance.address
}

# ALB endpoint
output "dns_name_alb" {
  value = aws_lb.wp_alb.dns_name
}

