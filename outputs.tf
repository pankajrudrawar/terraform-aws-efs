output "id" {
  description = "ID of the file system"
  value       = try(aws_efs_file_system.this[0].id, null)
}

output "arn" {
  description = "ARN of the file system"
  value       = try(aws_efs_file_system.this[0].arn, null)
}

output "dns_name" {
  description = "DNS name of the file system, for example `fs-12345678.efs.us-east-1.amazonaws.com`"
  value       = try(aws_efs_file_system.this[0].dns_name, null)
}

output "mount_target_ids" {
  description = "Map of mount target IDs keyed by the `mount_targets` key"
  value       = { for k, v in aws_efs_mount_target.this : k => v.id }
}

output "mount_target_dns_names" {
  description = "Map of mount target DNS names keyed by the `mount_targets` key"
  value       = { for k, v in aws_efs_mount_target.this : k => v.mount_target_dns_name }
}

output "access_point_ids" {
  description = "Map of access point IDs keyed by the `access_points` key"
  value       = { for k, v in aws_efs_access_point.this : k => v.id }
}

output "access_point_arns" {
  description = "Map of access point ARNs keyed by the `access_points` key"
  value       = { for k, v in aws_efs_access_point.this : k => v.arn }
}

output "security_group_id" {
  description = "ID of the security group created by this module"
  value       = try(aws_security_group.this[0].id, null)
}
