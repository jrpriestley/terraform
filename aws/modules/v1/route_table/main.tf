locals {
  rtas = flatten([
    for k1, v1 in var.route_tables : [
      for v2 in v1.subnets : {
        route_table = k1
        subnet      = v2
      }
    ]
  ])
}

data "aws_internet_gateway" "igw" {
  for_each = toset(flatten([
    for k1, v1 in var.route_tables : [
      for k2, v2 in v1.routes : substr(v2, 4, -1) if substr(v2, 0, 3) == "igw"
    ]
  ]))

  tags = {
    Name = each.value
  }
}

data "aws_nat_gateway" "ngw" {
  for_each = toset(flatten([
    for k1, v1 in var.route_tables : [
      for k2, v2 in v1.routes : substr(v2, 4, -1) if substr(v2, 0, 3) == "ngw"
    ]
  ]))

  state = "available"

  tags = {
    Name = each.value
  }
}

data "aws_network_interface" "nic" {
  for_each = toset(flatten([
    for k1, v1 in var.route_tables : [
      for k2, v2 in v1.routes : substr(v2, 4, -1) if substr(v2, 0, 3) == "nic"
    ]
  ]))

  id = each.value
  /*
  tags = {
    Name = each.value
  }
*/
}

data "aws_vpn_gateway" "vgw" {
  for_each = toset(flatten([
    for k1, v1 in var.route_tables : [
      for k2, v2 in v1.routes : substr(v2, 4, -1) if substr(v2, 0, 3) == "vgw"
    ]
  ]))

  tags = {
    Name = each.value
  }
}

data "aws_subnet" "subnet" {
  for_each = toset(flatten([for k1, v1 in var.route_tables : [for v2 in v1.subnets : [v2]]]))

  tags = {
    Name = each.key
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_route_table" "route_table" {
  for_each = var.route_tables

  vpc_id = data.aws_vpc.vpc.id

  dynamic "route" {
    for_each = each.value.routes

    content {
      cidr_block           = route.key
      gateway_id           = substr(route.value, 0, 3) == "igw" ? data.aws_internet_gateway.igw[substr(route.value, 4, -1)].id : substr(route.value, 0, 3) == "vgw" ? data.aws_vpn_gateway.vgw[substr(route.value, 4, -1)].id : ""
      nat_gateway_id       = substr(route.value, 0, 3) == "ngw" ? data.aws_nat_gateway.ngw[substr(route.value, 4, -1)].id : ""
      network_interface_id = substr(route.value, 0, 3) == "nic" ? data.aws_network_interface.nic[substr(route.value, 4, -1)].id : ""
    }
  }

  tags = merge(
    {
      Name              = each.key
      terraform_managed = "true"
    },
    each.value.tags
  )

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "aws_route_table_association" "association" {
  for_each = { for o in local.rtas : format("%s_%s", o.route_table, o.subnet) => o }

  route_table_id = aws_route_table.route_table[each.value.route_table].id
  subnet_id      = data.aws_subnet.subnet[each.value.subnet].id
}