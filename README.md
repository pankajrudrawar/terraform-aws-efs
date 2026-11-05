# terraform-aws-efs

Terraform module that creates an Amazon EFS file system with mount targets, access points, lifecycle tiering, backups and an optional security group.

[![Validate](https://github.com/pankajrudrawar/terraform-aws-efs/actions/workflows/validate.yml/badge.svg)](https://github.com/pankajrudrawar/terraform-aws-efs/actions/workflows/validate.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
![Terraform](https://img.shields.io/badge/terraform-%E2%89%A5%201.5.7-7B42BC?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-module-FF9900)

## Features

- Encrypted at rest by default, with optional customer-managed KMS key
- Elastic throughput by default; bursting and provisioned modes supported
- Lifecycle management for Infrequent Access, Archive and return-to-primary tiering
- AWS Backup policy enabled by default
- Mount targets and access points defined as maps, so adding an Availability Zone is a one-line change
- Optional security group with explicit, caller-defined NFS rules
- One Zone file systems through `availability_zone_name`
- Plan-time checks for the archive tier and provisioned throughput requirements
- `create = false` turns the whole module into a no-op

## Usage

```hcl
module "efs" {
  source = "github.com/pankajrudrawar/terraform-aws-efs"

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
```

A complete, runnable configuration is in [`examples/basic`](examples/basic).

## Notes

- Mount from a client with the EFS mount helper: `sudo mount -t efs -o tls <file-system-id>:/ /mnt/efs`.
- Mount target keys must be known at plan time. Use static keys such as `az1` or a zone name, not resource IDs.

## Module reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.7 |
| aws | >= 5.40 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create | Controls whether any resources are created by this module | `bool` | `true` | no |
| name | Name of the file system. Used for the Name tag and, unless overridden, the creation token | `string` | n/a | yes |
| creation_token | Unique creation token for idempotent creation. Defaults to `name` | `string` | `null` | no |
| availability_zone_name | Availability Zone for a One Zone file system, for example `us-east-1a`. Leave null for a Regional file system. Can only be set when the file system is created | `string` | `null` | no |
| encrypted | Whether the file system is encrypted at rest | `bool` | `true` | no |
| kms_key_id | ARN of the KMS key used for encryption. Uses the AWS-managed `aws/elasticfilesystem` key when null | `string` | `null` | no |
| performance_mode | File system performance mode: `generalPurpose` or `maxIO` | `string` | `"generalPurpose"` | no |
| throughput_mode | Throughput mode: `bursting`, `provisioned` or `elastic` | `string` | `"elastic"` | no |
| provisioned_throughput_in_mibps | Throughput in MiB/s to provision. Only used when `throughput_mode` is `provisioned` | `number` | `null` | no |
| lifecycle_policy | Lifecycle management settings. Each value is optional, for example `transition_to_ia = "AFTER_30_DAYS"` | `object` | `{}` | no |
| enable_backup_policy | Whether to enable automatic backups with AWS Backup | `bool` | `true` | no |
| file_system_policy | JSON resource policy to attach to the file system | `string` | `null` | no |
| bypass_policy_lockout_safety_check | Whether to bypass the lockout safety check when attaching `file_system_policy` | `bool` | `false` | no |
| mount_targets | Map of mount targets keyed by an arbitrary static name, typically one per Availability Zone | `map(object)` | `{}` | no |
| access_points | Map of access points keyed by an arbitrary static name | `map(object)` | `{}` | no |
| create_security_group | Whether to create a security group that is attached to every mount target | `bool` | `false` | no |
| security_group_name | Name of the security group. Defaults to `name` | `string` | `null` | no |
| security_group_description | Description of the security group | `string` | see `variables.tf` | no |
| vpc_id | ID of the VPC in which to create the security group. Required when `create_security_group` is true | `string` | `null` | no |
| security_group_ingress_rules | Map of ingress rules keyed by an arbitrary static name. Exactly one source (`cidr_ipv4`, `cidr_ipv6`, `prefix_list_id` or `referenced_security_group_id`) is required per rule | `map(object)` | `{}` | no |
| security_group_egress_rules | Map of egress rules keyed by an arbitrary static name. Allows all outbound traffic by default | `map(object)` | see `variables.tf` | no |
| tags | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | ID of the file system |
| arn | ARN of the file system |
| dns_name | DNS name of the file system, for example `fs-12345678.efs.us-east-1.amazonaws.com` |
| mount_target_ids | Map of mount target IDs keyed by the `mount_targets` key |
| mount_target_dns_names | Map of mount target DNS names keyed by the `mount_targets` key |
| access_point_ids | Map of access point IDs keyed by the `access_points` key |
| access_point_arns | Map of access point ARNs keyed by the `access_points` key |
| security_group_id | ID of the security group created by this module |
<!-- END_TF_DOCS -->

## Contributing

Issues and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first, and ask questions in [Discussions](https://github.com/pankajrudrawar/terraform-aws-efs/discussions). Run `pre-commit run -a` before opening a pull request. It formats the code, validates it, runs TFLint and refreshes the reference tables above with terraform-docs.

Security problems should be reported privately. See [SECURITY.md](SECURITY.md).

## License

Apache 2.0. See [LICENSE](LICENSE).
