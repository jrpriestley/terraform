locals {
  instances_security_groups = toset(flatten([
    for k1, v1 in data.aws_instance.instance : [
      for v2 in v1.vpc_security_group_ids : [v2]
    ]
  ]))
  instances = toset(flatten([
    for k, v in var.target_groups : [
      for i in range(0, length(data.aws_instances.instances[v.name].ids)) : [data.aws_instances.instances[v.name].ids[i]]
    ]
  ]))
  listeners_instances = toset(flatten([
    for k, v in var.listeners : [
      for i in range(0, length(data.aws_instances.instances[v.target_group].ids)) : {
        instance     = data.aws_instances.instances[v.target_group].ids[i]
        port         = v.port
        target_group = v.target_group
      }
    ]
  ]))
  listeners_security_groups = toset(flatten([
    for k1, v1 in var.listeners : [
      for k2, v2 in data.aws_instance.instance : [
        for v3 in v2.vpc_security_group_ids : {
          port                  = v1.port
          protocol              = v1.protocol
          security_group        = local.security_group_id_to_name[v3]
          security_group_id     = v3
          source_security_group = var.security_group
        }
      ]
    ]
  ]))
  security_group_id_to_name = { for k, v in data.aws_security_group.sg_instance : k => v.tags["Name"] }
}

data "aws_instance" "instance" {
  for_each = local.instances

  instance_id = each.value
}

data "aws_instances" "instances" {
  for_each = { for k, v in var.target_groups : v.name => v }

  filter {
    name   = format("tag:%s%s", each.value.instance_tag_prefix, each.key)
    values = ["true"]
  }
}

data "aws_security_group" "sg_instance" {
  for_each = local.instances_security_groups

  id = each.value
}

data "aws_security_group" "sg_lb" {
  tags = {
    Name = var.security_group
  }
}

data "aws_subnet" "subnet" {
  for_each = toset(var.subnets)

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
  name               = var.name
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups    = [data.aws_security_group.sg_lb.id]
  subnets            = [for v in data.aws_subnet.subnet : v.id]

  tags = merge(
    {
      Name              = var.name
      terraform_managed = "true"
    },
    var.tags
  )
}

resource "aws_lb_target_group" "tg" {
  for_each = { for k, v in var.target_groups : v.name => v }

  name     = each.key
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = data.aws_vpc.vpc.id
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  for_each = { for v in local.listeners_instances : format("%s_%s", v.target_group, v.instance) => v }

  target_group_arn = aws_lb_target_group.tg[each.value.target_group].arn
  target_id        = each.value.instance
  port             = each.value.port
}

resource "aws_lb_listener" "listener" {
  for_each = { for k, v in var.listeners : v.target_group => v }

  load_balancer_arn = aws_lb.lb.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.key].arn
  }
}

resource "aws_security_group_rule" "sgr_instance" {
  for_each = { for v in local.listeners_security_groups : format("%s_%s_%s", v.security_group, v.protocol, v.port) => v }

  security_group_id        = each.value.security_group_id
  source_security_group_id = data.aws_security_group.sg_lb.id
  description              = format("allow %s traffic from %s", each.value.protocol, each.value.source_security_group)
  from_port                = each.value.port
  protocol                 = "tcp"
  to_port                  = each.value.port
  type                     = "ingress"
}

resource "aws_security_group_rule" "sgr_lb" {
  for_each = { for v in var.listeners : format("%s_%s", v.protocol, v.port) => v if var.add_lb_security_group_rules == true }

  security_group_id = data.aws_security_group.sg_lb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = format("allow %s traffic from any", each.value.protocol)
  from_port         = each.value.port
  protocol          = "tcp"
  to_port           = each.value.port
  type              = "ingress"
}