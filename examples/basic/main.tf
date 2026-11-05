terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC that will host the file system"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs, one per Availability Zone"
  type        = list(string)
}

variable "client_cidr_blocks" {
  description = "CIDR blocks of NFS clients"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

module "efs" {
  source = "../.."

  name = "example-efs"

  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  create_security_group = true
  vpc_id                = var.vpc_id

  security_group_ingress_rules = {
    for idx, cidr in var.client_cidr_blocks : "nfs_${idx}" => {
      description = "NFS from clients"
      cidr_ipv4   = cidr
    }
  }

  mount_targets = {
    for idx, subnet_id in var.subnet_ids : "az${idx}" => {
      subnet_id = subnet_id
    }
  }

  access_points = {
    app = {
      posix_user = {
        uid = 1000
        gid = 1000
      }
      root_directory = {
        path = "/app"
        creation_info = {
          owner_uid   = 1000
          owner_gid   = 1000
          permissions = "0750"
        }
      }
    }
  }

  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}

output "file_system_id" {
  value = module.efs.id
}

output "dns_name" {
  value = module.efs.dns_name
}
