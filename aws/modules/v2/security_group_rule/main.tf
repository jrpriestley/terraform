locals {
  security_group_rules = concat(local.security_group_rules_egress, local.security_group_rules_ingress)
  security_group_rules_egress = flatten([
    for k1, v1 in var.security_group_rules : [
      for k2, v2 in v1.egress : [
        for v3 in v2.endpoints : {
          cidr_blocks             = substr(v3, 0, 4) == "cidr" ? substr(v3, 5, -1) : null
          description             = v2.description
          direction               = "egress"
          from_port               = v2.from_port
          protocol                = v2.protocol
          security_group          = v1.security_group
          security_group_endpoint = substr(v3, 0, 2) == "sg" ? substr(v3, 3, -1) : null
          to_port                 = v2.to_port
        }
      ]
    ]
  ])
  security_group_rules_ingress = flatten([
    for k1, v1 in var.security_group_rules : [
      for k2, v2 in v1.ingress : [
        for v3 in v2.endpoints : {
          cidr_blocks             = substr(v3, 0, 4) == "cidr" ? substr(v3, 5, -1) : null
          description             = v2.description
          direction               = "ingress"
          from_port               = v2.from_port
          protocol                = v2.protocol
          security_group          = v1.security_group
          security_group_endpoint = substr(v3, 0, 2) == "sg" ? substr(v3, 3, -1) : null
          to_port                 = v2.to_port
        }
      ]
    ]
  ])
  security_groups = toset(flatten([for k, v in var.security_group_rules : [v.security_group]]))
  security_groups_endpoints_egress = toset(flatten([
    for k1, v1 in var.security_group_rules : [
      for k2, v2 in v1.egress : [
        for v3 in v2.endpoints : [substr(v3, 3, -1)] if substr(v3, 0, 2) == "sg"
      ]
    ]
  ]))
  security_groups_endpoints_ingress = toset(flatten([
    for k1, v1 in var.security_group_rules : [
      for k2, v2 in v1.ingress : [
        for v3 in v2.endpoints : [substr(v3, 3, -1)] if substr(v3, 0, 2) == "sg"
      ]
    ]
  ]))
}

data "aws_security_group" "sg" {
  for_each = setunion(local.security_groups, local.security_groups_endpoints_egress, local.security_groups_endpoints_ingress)

  tags = {
    Name = each.value
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_security_group_rule" "sgr_cidr" {
  for_each = { for v in local.security_group_rules : format("%s_%s_%s_%s_%s", v.security_group, v.direction, v.cidr_blocks, v.protocol, v.to_port) => v if v.cidr_blocks != null }

  security_group_id = data.aws_security_group.sg[each.value.security_group].id
  cidr_blocks       = [each.value.cidr_blocks]
  description       = each.value.description
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  to_port           = each.value.to_port
  type              = each.value.direction

  lifecycle {
    ignore_changes = [
      security_group_id,
    ]
  }
}

resource "aws_security_group_rule" "sgr_sg" {
  for_each = { for v in local.security_group_rules : format("%s_%s_%s_%s_%s", v.security_group, v.direction, v.security_group_endpoint, v.protocol, v.to_port) => v if v.security_group_endpoint != null }

  security_group_id        = data.aws_security_group.sg[each.value.security_group].id
  source_security_group_id = data.aws_security_group.sg[each.value.security_group_endpoint].id
  description              = each.value.description
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  to_port                  = each.value.to_port
  type                     = each.value.direction

  lifecycle {
    ignore_changes = [
      security_group_id,
      source_security_group_id,
    ]
  }
}