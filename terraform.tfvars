# terraform.tfvars
aws_region           = "us-west-2"
db_name              = "acmedemo"
db_instance_class    = "db.t3.medium"
db_allocated_storage = 50
db_engine_version    = "16.6"
db_username          = "acme_admin"
# vpc_id = "vpc-12345abcdef"
# subnet_ids = ["subnet-12345a", "subnet-67890b", "subnet-abcdef"]
backup_retention_period = 14
multi_az                = true
skip_final_snapshot     = true
deletion_protection     = false
environment             = "dev"