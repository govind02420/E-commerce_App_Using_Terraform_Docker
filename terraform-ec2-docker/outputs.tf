output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "frontend_url" {
  description = "Frontend URL"
  value       = "http://${aws_instance.app.public_ip}:3000"
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.instance_sg.id
}
