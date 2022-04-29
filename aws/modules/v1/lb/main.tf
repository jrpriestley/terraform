locals {
  instances = toset(flatten([
    for k, v in var.target_groups : [
      for i in range(0, length(data.aws_instances.instances[k].ids)) : [
        data.aws_instances.instances[k].ids[i]
      ]
    ]
  ]))

  lb_instances = toset(flatten([
    for k, v in local.lb_listeners : [
      for i in range(0, length(data.aws_instances.instances[v.target_group].ids)) : {
        instance     = data.aws_instances.instances[v.target_group].ids[i]
        lb           = v.lb
        port         = v.port
        target_group = v.target_group
      }
    ]
  ]))

  lb_listeners = toset(flatten([
    for k1, v1 in var.load_balancers : [
      for k2, v2 in v1.listeners : {
        lb           = k1
        port         = v2.port
        protocol     = v2.protocol
        target_group = v2.target_group
      }
    ]
  ]))

  security_group_id_to_name = { for k, v in data.aws_security_group.security_group_instance : k => v.tags["Name"] }

  security_group_instances = toset(distinct(flatten([
    for k1, v1 in data.aws_instance.instance : [
      for v2 in v1.vpc_security_group_ids : [v2]
    ]
  ])))

  security_group_instances_mapping = toset(flatten([
    for k1, v1 in var.load_balancers : [
      for k2, v2 in v1.listeners : [
        for k3, v3 in data.aws_instance.instance : [
          for v4 in v3.vpc_security_group_ids : {
            lb                    = k1
            port                  = v2.port
            protocol              = v2.protocol
            security_group        = local.security_group_id_to_name[v4]
            security_group_id     = v4
            source_security_group = v1.security_group
          }
        ]
      ]
    ]
  ]))

  security_group_listeners = toset(flatten([
    for k1, v1 in var.load_balancers : [
      for k2, v2 in v1.listeners : {
        lb             = k1
        port           = v2.port
        protocol       = v2.protocol
        security_group = v1.security_group
      }
    ]
    if v1.add_lb_security_group_rules
  ]))
}

data "aws_instance" "instance" {
  for_each = local.instances

  instance_id = each.value
}

data "aws_instances" "instances" {
  for_each = var.target_groups

  filter {
    name   = format("tag:%s%s", each.value.instance_tag_prefix, each.key)
    values = ["true"]
  }
}

data "aws_security_group" "security_group_instance" {
  for_each = local.security_group_instances

  id = each.value
}

data "aws_security_group" "security_group_lb" {
  for_each = { for k, v in var.load_balancers : v.security_group => v }

  tags = {
    Name = each.value.security_group
  }
}

data "aws_subnet" "subnet" {
  for_each = toset(flatten([
    for k, v in var.load_balancers : [
      for subnet in v.subnets : [subnet]
    ]
  ]))

  tags = {
    Name = each.value
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_lb" "lb" {
  for_each = var.load_balancers

  name               = each.key
  internal           = each.value.internal
  load_balancer_type = each.value.load_balancer_type
  security_groups    = [data.aws_security_group.security_group_lb[each.value.security_group].id]
  subnets            = [for k in data.aws_subnet.subnet : k.id]

  tags = merge(
    {
      Name              = each.key
      terraform_managed = "true"
    },
    each.value.tags
  )
}

resource "aws_lb_target_group" "target_group" {
  for_each = var.target_groups

  name     = each.key
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = data.aws_vpc.vpc.id
}

resource "aws_lb_target_group_attachment" "tga" {
  for_each = { for o in local.lb_instances : format("%s_%s_%s", o.lb, o.target_group, o.instance) => o }

  target_group_arn = aws_lb_target_group.target_group[each.value.target_group].arn
  target_id        = each.value.instance
  port             = each.value.port
}

resource "aws_lb_listener" "listener" {
  for_each = { for o in local.lb_listeners : format("%s_%s_%s", o.lb, o.protocol, o.port) => o }

  load_balancer_arn = aws_lb.lb[each.value.lb].arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[each.value.target_group].arn
  }
}

resource "aws_security_group_rule" "security_group_rule_instance" {
  for_each = { for o in local.security_group_instances_mapping : format("%s_%s_%s", o.security_group, o.protocol, o.port) => o }

  security_group_id        = data.aws_security_group.security_group_instance[each.value.security_group_id].id
  source_security_group_id = data.aws_security_group.security_group_lb[each.value.source_security_group].id
  description              = format("allow %s traffic from %s", each.value.protocol, each.value.source_security_group)
  from_port                = each.value.port
  protocol                 = "tcp"
  to_port                  = each.value.port
  type                     = "ingress"
}

resource "aws_security_group_rule" "security_group_rule_lb" {
  for_each = { for o in local.security_group_listeners : format("%s_%s_%s", o.security_group, o.protocol, o.port) => o }

  security_group_id = data.aws_security_group.security_group_lb[each.value.security_group].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = format("allow %s traffic from any", each.value.protocol)
  from_port         = each.value.port
  protocol          = "tcp"
  to_port           = each.value.port
  type              = "ingress"
}