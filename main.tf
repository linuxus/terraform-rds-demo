# main.tf

# Access remote state from the EKS deployment workspace
data "terraform_remote_state" "eks_deployment" {
  backend = "remote"

  config = {
    organization = "abdi-sbx"
    workspaces = {
      name = var.eks_deployment_workspace
    }
  }
}

locals {
  subnet_ids = data.terraform_remote_state.eks_deployment.outputs.private_subnets
  vpc_id     = data.terraform_remote_state.eks_deployment.outputs.vpc_id
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "acme-db-subnet-group"
  subnet_ids = local.subnet_ids

  tags = {
    Name        = "ACME PostgreSQL DB Subnet Group"
    Environment = var.environment
  }
}

resource "aws_security_group" "db_sg" {
  name        = "acme-db-security-group"
  description = "Security group for ACME PostgreSQL database"
  vpc_id      = local.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Adjust to your VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ACME PostgreSQL DB Security Group"
    Environment = var.environment
  }
}

resource "aws_db_parameter_group" "db_pg" {
  name   = "acme-pg-param-group"
  family = "postgres16"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = {
    Name        = "ACME PostgreSQL Parameter Group"
    Environment = var.environment
  }
}

resource "aws_db_instance" "postgresql" {
  identifier             = "acme-postgresql"
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  parameter_group_name   = aws_db_parameter_group.db_pg.name
  
  backup_retention_period      = var.backup_retention_period
  backup_window                = "03:00-06:00"
  maintenance_window           = "Mon:00:00-Mon:03:00"
  multi_az                     = var.multi_az
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.skip_final_snapshot ? null : "acme-demo-final-snapshot"
  deletion_protection          = var.deletion_protection
  storage_encrypted            = true
  
  tags = {
    Name        = "ACME PostgreSQL Database"
    Environment = var.environment
  }
}