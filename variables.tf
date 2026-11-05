variable "create" {
  description = "Controls whether any resources are created by this module"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the file system. Used for the Name tag and, unless overridden, the creation token"
  type        = string
}

variable "creation_token" {
  description = "Unique creation token for idempotent creation. Defaults to `name`"
  type        = string
  default     = null
}

variable "encrypted" {
  description = "Whether the file system is encrypted at rest"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "ARN of the KMS key used for encryption. Uses the AWS-managed `aws/elasticfilesystem` key when null"
  type        = string
  default     = null
}

variable "performance_mode" {
  description = "File system performance mode: `generalPurpose` or `maxIO`"
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "performance_mode must be \"generalPurpose\" or \"maxIO\"."
  }
}

variable "throughput_mode" {
  description = "Throughput mode: `bursting`, `provisioned` or `elastic`"
  type        = string
  default     = "elastic"

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "throughput_mode must be one of \"bursting\", \"provisioned\" or \"elastic\"."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "Throughput in MiB/s to provision. Only used when `throughput_mode` is `provisioned`"
  type        = number
  default     = null
}

variable "lifecycle_policy" {
  description = "Lifecycle management settings. Each value is optional, for example `transition_to_ia = \"AFTER_30_DAYS\"`"
  type = object({
    transition_to_ia                    = optional(string)
    transition_to_primary_storage_class = optional(string)
    transition_to_archive               = optional(string)
  })
  default = {}
}

variable "enable_backup_policy" {
  description = "Whether to enable automatic backups with AWS Backup"
  type        = bool
  default     = true
}

variable "file_system_policy" {
  description = "JSON resource policy to attach to the file system"
  type        = string
  default     = null
}

variable "bypass_policy_lockout_safety_check" {
  description = "Whether to bypass the lockout safety check when attaching `file_system_policy`"
  type        = bool
  default     = false
}

variable "mount_targets" {
  description = "Map of mount targets keyed by an arbitrary static name, typically one per Availability Zone"
  type = map(object({
    subnet_id       = string
    ip_address      = optional(string)
    security_groups = optional(list(string), [])
  }))
  default = {}
}

variable "access_points" {
  description = "Map of access points keyed by an arbitrary static name"
  type = map(object({
    posix_user = optional(object({
      uid            = number
      gid            = number
      secondary_gids = optional(list(number))
    }))
    root_directory = optional(object({
      path = optional(string)
      creation_info = optional(object({
        owner_uid   = number
        owner_gid   = number
        permissions = string
      }))
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

################################################################################
# Security group
################################################################################

variable "create_security_group" {
  description = "Whether to create a security group that is attached to every mount target"
  type        = bool
  default     = false
}

variable "security_group_name" {
  description = "Name of the security group. Defaults to `name`"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description of the security group"
  type        = string
  default     = "Security group for the EFS file system"
}

variable "vpc_id" {
  description = "ID of the VPC in which to create the security group. Required when `create_security_group` is true"
  type        = string
  default     = null
}

variable "security_group_ingress_rules" {
  description = "Map of ingress rules keyed by an arbitrary static name. Exactly one source (`cidr_ipv4`, `cidr_ipv6`, `prefix_list_id` or `referenced_security_group_id`) is required per rule"
  type = map(object({
    description                  = optional(string)
    from_port                    = optional(number, 2049)
    to_port                      = optional(number, 2049)
    ip_protocol                  = optional(string, "tcp")
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = {}
}

variable "security_group_egress_rules" {
  description = "Map of egress rules keyed by an arbitrary static name. Allows all outbound traffic by default"
  type = map(object({
    description                  = optional(string)
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = optional(string, "-1")
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
  }))
  default = {
    all_ipv4 = {
      description = "Allow all outbound IPv4 traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
