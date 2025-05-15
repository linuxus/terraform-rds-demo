# EC2 Bastion Host with SSM Access for RDS Connection

# SSM VPC Endpoints
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Adjust to match your VPC CIDR block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "VPC Endpoint Security Group"
    Environment = var.environment
  }
}

# SSM Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name        = "SSM VPC Endpoint"
    Environment = var.environment
  }
}

# SSM Messages Endpoint
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name        = "SSM Messages VPC Endpoint"
    Environment = var.environment
  }
}

# EC2 Messages Endpoint
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name        = "EC2 Messages VPC Endpoint"
    Environment = var.environment
  }
}

# IAM Role for EC2 Bastion with SSM access
resource "aws_iam_role" "bastion_role" {
  name = "ec2-bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "EC2 Bastion SSM Role"
    Environment = var.environment
  }
}

# Attach the AmazonSSMManagedInstanceCore policy
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create an instance profile
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "ec2-bastion-profile"
  role = aws_iam_role.bastion_role.name
}

# Security Group for the bastion host
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-security-group"
  description = "Security group for bastion host"
  vpc_id      = local.vpc_id

  # No inbound rules needed for SSM, but add PostgreSQL for RDS access
  ingress {
    description     = "PostgreSQL from DB Security Group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.db_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Bastion Host Security Group"
    Environment = var.environment
  }
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Bastion Instance
resource "aws_instance" "bastion" {
  ami                    = var.bastion_ami_id != "" ? var.bastion_ami_id : data.aws_ami.amazon_linux_2.id
  instance_type          = var.bastion_instance_type
  subnet_id              = local.subnet_ids[0]  # Use first private subnet
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  root_block_device {
    volume_size = 8
    encrypted   = true
  }

  # User data to install PostgreSQL client
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras enable postgresql14
    yum install -y postgresql
  EOF

  tags = {
    Name        = "RDS Bastion Host"
    Environment = var.environment
  }
}

# Update the DB security group to allow access from the bastion
resource "aws_security_group_rule" "db_from_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.db_sg.id
  description              = "PostgreSQL from Bastion Host"
}