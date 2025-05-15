# providers.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "abdi-sbx"

    workspaces {
      name    = "terraform-rds-demo"
      project = "ACME-Demo"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

