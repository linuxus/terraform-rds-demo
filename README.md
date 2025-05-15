# AWS RDS PostgreSQL with Secure SSM Access

This repository contains Terraform configurations for deploying a secure PostgreSQL RDS instance in AWS private subnets with secure access via AWS Systems Manager (SSM) Session Manager.

## Architecture Overview

The solution consists of two main components:

1. **RDS PostgreSQL Database**: Deployed in private subnets within a VPC
2. **EC2 Bastion Host**: For secure access to the database via SSM

## Infrastructure Components

### Network Infrastructure
- Uses existing VPC and subnets from a remote Terraform workspace
- Security groups for all components
- VPC Endpoints for SSM connectivity

### Database Infrastructure
- Amazon RDS PostgreSQL instance
- DB subnet group in private subnets
- Database parameter group with logging enabled
- Multi-AZ deployment for high availability
- Encrypted storage
- Automated backups

### Access Infrastructure
- EC2 bastion host (t3.micro) in a private subnet
- IAM role with SSM policy
- SSM VPC Endpoints (ssm, ssmmessages, ec2messages)
- Port forwarding via SSM to securely access RDS

## Prerequisites

- AWS CLI installed and configured
- Terraform v1.0+ installed
- Terraform Cloud account
- Existing EKS deployment with VPC and subnets

## Files Description

| File | Description |
|------|-------------|
| `main.tf` | Main Terraform configuration for RDS PostgreSQL |
| `ec2-bastion.tf` | EC2 bastion host with SSM access configuration |
| `variables.tf` | Input variables for the Terraform modules |
| `outputs.tf` | Output values after Terraform deployment |
| `providers.tf` | Provider configurations for AWS and Terraform Cloud |
| `terraform.tfvars` | Variable values for the deployment |
| `ssm-rds-tunnel.sh` | Shell script for manual SSM port forwarding |

## Deployment Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Update Configuration

Review and modify the following files:

1. **terraform.tfvars**: Update with your desired configuration values
2. **providers.tf**: Update with your Terraform Cloud organization and workspace

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan the Deployment

```bash
terraform plan
```

### 5. Apply the Configuration

```bash
terraform apply
```

Confirm the changes when prompted.

## Accessing the Database

After deployment, you can access the PostgreSQL database using the SSM port forwarding:

### Option 1: Use the Terraform Output Command

```bash
# Get the SSM connection command
terraform output -raw ssm_connection_command

# In another terminal, connect to PostgreSQL after SSM tunnel is established
terraform output -raw psql_connect_command
```

### Option 2: Use the Provided Shell Script

Update the `ssm-rds-tunnel.sh` script with the output values and run:

```bash
chmod +x ssm-rds-tunnel.sh
./ssm-rds-tunnel.sh
```

In another terminal, connect to PostgreSQL:

```bash
psql -h localhost -p 5432 -U <username> -d <dbname>
```

## Security Features

This solution implements several security best practices:

1. **No Public Access**: 
   - RDS is deployed in private subnets
   - EC2 bastion host is in private subnet with no public IP

2. **Encrypted Communication**:
   - All traffic flows through AWS private network
   - Database storage is encrypted

3. **Least Privilege Access**:
   - IAM roles with minimum required permissions
   - Security groups with tight access controls

4. **No SSH Keys Required**:
   - Using SSM Session Manager eliminates need for SSH key management
   - All access is authenticated through AWS IAM

5. **Auditing**:
   - Database connection logging enabled
   - SSM sessions can be logged to CloudWatch

## Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | us-east-1 |
| `db_name` | PostgreSQL database name | acme-demo |
| `db_instance_class` | RDS instance type | db.t3.micro |
| `db_allocated_storage` | Storage size in GB | 20 |
| `db_engine_version` | PostgreSQL version | 14 |
| `db_username` | Database admin username | postgres |
| `backup_retention_period` | Backup retention in days | 7 |
| `multi_az` | Enable Multi-AZ deployment | false |
| `environment` | Environment tag | dev |
| `bastion_instance_type` | EC2 bastion instance type | t3.micro |
| `eks_deployment_workspace` | Terraform workspace with VPC | terraform-eks-demo |

## Outputs Reference

| Output | Description |
|--------|-------------|
| `db_instance_endpoint` | RDS connection endpoint |
| `db_instance_port` | RDS port number |
| `db_instance_name` | Database name |
| `bastion_instance_id` | EC2 bastion instance ID |
| `ssm_connection_command` | Command to establish SSM tunnel |
| `psql_connect_command` | Command to connect to PostgreSQL |

## Cleanup

To destroy all resources created by this Terraform configuration:

```bash
terraform destroy
```

## Additional Considerations

- **Performance**: For production workloads, consider using a larger instance type
- **Monitoring**: Add CloudWatch alarms for database metrics
- **Backup Strategy**: Review backup settings for production databases
- **Parameter Tuning**: Customize PostgreSQL parameters based on workload
- **Cost Optimization**: Use reserved instances for production databases
