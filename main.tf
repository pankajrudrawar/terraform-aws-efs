locals {
  create_security_group = var.create && var.create_security_group
  security_group_name   = coalesce(var.security_group_name, var.name)
  security_group_ids    = local.create_security_group ? [aws_security_group.this[0].id] : []
}

################################################################################
# File system
################################################################################

resource "aws_efs_file_system" "this" {
  count = var.create ? 1 : 0

  creation_token                  = coalesce(var.creation_token, var.name)
  encrypted                       = var.encrypted
  kms_key_id                      = var.kms_key_id
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy.transition_to_ia != null ? [1] : []

    content {
      transition_to_ia = var.lifecycle_policy.transition_to_ia
    }
  }

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy.transition_to_primary_storage_class != null ? [1] : []

    content {
      transition_to_primary_storage_class = var.lifecycle_policy.transition_to_primary_storage_class
    }
  }

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy.transition_to_archive != null ? [1] : []

    content {
      transition_to_archive = var.lifecycle_policy.transition_to_archive
    }
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_efs_backup_policy" "this" {
  count = var.create && var.enable_backup_policy ? 1 : 0

  file_system_id = aws_efs_file_system.this[0].id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_file_system_policy" "this" {
  count = var.create && var.file_system_policy != null ? 1 : 0

  file_system_id                     = aws_efs_file_system.this[0].id
  policy                             = var.file_system_policy
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check
}

################################################################################
# Mount targets
################################################################################

resource "aws_efs_mount_target" "this" {
  for_each = var.create ? var.mount_targets : {}

  file_system_id  = aws_efs_file_system.this[0].id
  subnet_id       = each.value.subnet_id
  ip_address      = each.value.ip_address
  security_groups = concat(local.security_group_ids, each.value.security_groups)
}

################################################################################
# Access points
################################################################################

resource "aws_efs_access_point" "this" {
  for_each = var.create ? var.access_points : {}

  file_system_id = aws_efs_file_system.this[0].id

  dynamic "posix_user" {
    for_each = each.value.posix_user != null ? [each.value.posix_user] : []

    content {
      uid            = posix_user.value.uid
      gid            = posix_user.value.gid
      secondary_gids = posix_user.value.secondary_gids
    }
  }

  dynamic "root_directory" {
    for_each = each.value.root_directory != null ? [each.value.root_directory] : []

    content {
      path = root_directory.value.path

      dynamic "creation_info" {
        for_each = root_directory.value.creation_info != null ? [root_directory.value.creation_info] : []

        content {
          owner_uid   = creation_info.value.owner_uid
          owner_gid   = creation_info.value.owner_gid
          permissions = creation_info.value.permissions
        }
      }
    }
  }

  tags = merge(var.tags, each.value.tags, { Name = "${var.name}-${each.key}" })
}

################################################################################
# Security group
################################################################################

resource "aws_security_group" "this" {
  count = local.create_security_group ? 1 : 0

  name        = local.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = local.security_group_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.create_security_group ? var.security_group_ingress_rules : {}

  security_group_id = aws_security_group.this[0].id

  description                  = each.value.description
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id

  tags = merge(var.tags, { Name = "${local.security_group_name}-${each.key}" })
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = local.create_security_group ? var.security_group_egress_rules : {}

  security_group_id = aws_security_group.this[0].id

  description                  = each.value.description
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id

  tags = merge(var.tags, { Name = "${local.security_group_name}-${each.key}" })
}
