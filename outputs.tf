# Outputs
output "db_instance_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.postgresql.endpoint
}

output "db_instance_address" {
  description = "The hostname of the database instance"
  value       = aws_db_instance.postgresql.address
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.postgresql.port
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.postgresql.db_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = aws_db_instance.postgresql.username
  sensitive   = true
}

output "db_instance_password" {
  description = "The master password for the database"
  value       = random_password.db_password.result
  sensitive   = true
}

# Additional outputs for EC2 bastion host

output "bastion_instance_id" {
  description = "The ID of the bastion EC2 instance"
  value       = aws_instance.bastion.id
}

output "ssm_connection_command" {
  description = "Command to connect to the database via SSM port forwarding"
  value       = <<-EOT
    aws ssm start-session \
      --target ${aws_instance.bastion.id} \
      --region ${var.aws_region} \
      --document-name AWS-StartPortForwardingSessionToRemoteHost \
      --parameters "host=${aws_db_instance.postgresql.address},portNumber=5432,localPortNumber=5432"
  EOT
}

output "bastion_connect_command" {
  description = "Command to connect to the bastion host via SSM"
  value       = "aws ssm start-session --target ${aws_instance.bastion.id} --region ${var.aws_region}"
}

output "psql_connect_command" {
  description = "PostgreSQL command to connect to the database after establishing SSM tunnel"
  value       = "psql -h localhost -p 5432 -U ${var.db_username} -d ${var.db_name}"
  sensitive   = true
}