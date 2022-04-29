locals {
  rgs_from = toset(flatten([
    for k1, v1 in var.network_security_group_rules : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : [
          for v4 in v3.source : [
            split("/", substr(v4, 5, -1))[0]
          ] if substr(v4, 0, 4) == "snet"
        ]
      ]
    ]
  ]))
  rgs_to = toset(flatten([
    for k1, v1 in var.network_security_group_rules : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : [
          for v4 in v3.destination : [
            split("/", substr(v4, 5, -1))[0]
          ] if substr(v4, 0, 4) == "snet"
        ]
      ]
    ]
  ]))
  rules_custom = toset(flatten([
    for k1, v1 in var.network_security_group_rules : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : {
          nsg            = v1.security_group
          resource_group = v1.resource_group
          description    = v3.description
          priority       = v3.priority
          direction      = replace(replace(k2, "egress", "Outbound"), "ingress", "Inbound")
          access         = title(v3.access)
          protocol       = title(v3.protocol)
          from_port      = v3.from_port
          to_port        = v3.to_port
          source         = lookup(local.rules_map, format("%s_%s_%s-src", v1.security_group, k2, v3.priority))
          destination    = lookup(local.rules_map, format("%s_%s_%s-dst", v1.security_group, k2, v3.priority))
        }
      ]
    ]
  ]))
  rules_from = flatten([
    for k1, v1 in var.network_security_group_rules : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : [
          for v4 in v3.source : {
            rule    = format("%s_%s_%s-src", v1.security_group, k2, v3.priority)
            sources = lookup(local.snets_map, substr(v4, 5, -1), replace(v4, "cidr:", ""))
          }
        ]
      ]
    ]
  ])
  rules_from_map = { for v in local.rules_from : v.rule => v.sources... }
  rules_map      = merge(local.rules_from_map, local.rules_to_map)
  rules_to = flatten([
    for k1, v1 in var.network_security_group_rules : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : [
          for v4 in v3.destination : {
            rule    = format("%s_%s_%s-dst", v1.security_group, k2, v3.priority)
            sources = lookup(local.snets_map, substr(v4, 5, -1), replace(v4, "cidr:", ""))
          }
        ]
      ]
    ]
  ])
  rules_to_map = { for v in local.rules_to : v.rule => v.sources... }
  snets_from = toset(flatten([
    for k1, v1 in var.network_security_group_rules : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : [
          for v4 in v3.source : [
            substr(v4, 5, -1)
          ] if substr(v4, 0, 4) == "snet"
        ]
      ]
    ]
  ]))
  snets_from_map = { for v in local.snets_from : v => data.azurerm_subnet.snet[v].address_prefix }
  snets_map      = merge(local.snets_from_map, local.snets_to_map)
  snets_to = toset(flatten([
    for k1, v1 in var.network_security_group_rules : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : [
          for v4 in v3.destination : [
            substr(v4, 5, -1)
          ] if substr(v4, 0, 4) == "snet"
        ]
      ]
    ]
  ]))
  snets_to_map = { for v in local.snets_to : v => data.azurerm_subnet.snet[v].address_prefix }
  vnets_from = toset(flatten([
    for k1, v1 in var.network_security_group_rules : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : [
          for v4 in v3.source : [
            substr("${split("/", v4)[0]}/${split("/", v4)[1]}", 5, -1)
          ] if substr(v4, 0, 4) == "snet"
        ]
      ]
    ]
  ]))
  vnets_to = toset(flatten([
    for k1, v1 in var.network_security_group_rules : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : [
          for v4 in v3.destination : [
            substr("${split("/", v4)[0]}/${split("/", v4)[1]}", 5, -1)
          ] if substr(v4, 0, 4) == "snet"
        ]
      ]
    ]
  ]))
}

data "azurerm_resource_group" "rg" {
  for_each = setunion(local.rgs_from, local.rgs_to)

  name = each.value
}

data "azurerm_subnet" "snet" {
  for_each = setunion(local.snets_from, local.snets_to)

  resource_group_name  = split("/", each.value)[0]
  name                 = split("/", each.value)[2]
  virtual_network_name = split("/", each.value)[1]
}

data "azurerm_virtual_network" "vnet" {
  for_each = setunion(local.vnets_from, local.vnets_to)

  resource_group_name = split("/", each.value)[0]
  name                = split("/", each.value)[1]
}

resource "azurerm_network_security_rule" "nsgr-custom" {
  for_each = { for k, v in local.rules_custom : format("%s_%s_%s", v.nsg, v.direction, v.priority) => v }

  resource_group_name          = each.value.resource_group
  network_security_group_name  = each.value.nsg
  name                         = each.value.description
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.from_port[0] == "*" ? "*" : null
  source_port_ranges           = each.value.from_port[0] != "*" ? each.value.from_port : null
  destination_port_range       = each.value.to_port[0] == "*" ? "*" : null
  destination_port_ranges      = each.value.to_port[0] != "*" ? each.value.to_port : null
  source_address_prefix        = length(each.value.source) == 1 ? each.value.source[0] : null
  source_address_prefixes      = length(each.value.source) > 1 ? each.value.source : null
  destination_address_prefix   = length(each.value.destination) == 1 ? each.value.destination[0] : null
  destination_address_prefixes = length(each.value.destination) > 1 ? each.value.destination : null
}