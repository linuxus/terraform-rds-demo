# variables.tf
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "acme-demo"
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "14"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID where database will be deployed"
  type        = string
  default     = "vpc-12345abcdef"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
  default     = ["subnet-12345a", "subnet-67890b", "subnet-abcdef"]
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "If true, enable multi-AZ deployment"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "If true, skip final snapshot when the database is deleted"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "If true, enable deletion protection"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "dev"
}

variable "eks_deployment_workspace" {
  description = "Name of the Terraform Cloud workspace that deployed Vault"
  type        = string
  default = "terraform-eks-demo"
}

# Additional variables for the EC2 bastion host

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_ami_id" {
  description = "AMI ID for the bastion host (leave empty to use latest Amazon Linux 2)"
  type        = string
  default     = ""
}

variable "enable_ssm_vpc_endpoints" {
  description = "Whether to create SSM VPC endpoints"
  type        = bool
  default     = true
}