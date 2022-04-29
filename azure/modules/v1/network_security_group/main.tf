locals {
  rgs_from = toset(flatten([
    for k1, v1 in var.network_security_groups : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : [
          for v4 in v3.source : [
            split("/", substr(v4, 5, -1))[0]
          ] if substr(v4, 0, 4) == "snet"
        ]
      ]
    ]
  ]))
  rgs_home = toset(flatten([for k1, v1 in var.network_security_groups : [v1.resource_group]]))
  rgs_to = toset(flatten([
    for k1, v1 in var.network_security_groups : [
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
    for k1, v1 in var.network_security_groups : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : {
          nsg            = k1
          resource_group = v1.resource_group
          description    = v3.description
          priority       = v3.priority
          direction      = replace(replace(k2, "egress", "Outbound"), "ingress", "Inbound")
          access         = title(v3.access)
          protocol       = title(v3.protocol)
          from_port      = v3.from_port
          to_port        = v3.to_port
          source         = lookup(local.rules_map, format("%s_%s_%s-src", k1, k2, v3.priority))
          destination    = lookup(local.rules_map, format("%s_%s_%s-dst", k1, k2, v3.priority))
        }
      ]
    ]
  ]))
  rules_intra = toset(flatten([
    for k, v in var.network_security_groups : {
      nsg            = k
      resource_group = v.resource_group
      description    = format("allow any from same subnet")
      priority       = 100
      direction      = "Inbound"
      access         = "Allow"
      protocol       = "*"
      from_port      = "*"
      to_port        = "*"
      source         = lookup(local.rules_intra_map, k)
      destination    = lookup(local.rules_intra_map, k)
    } if v.allow_same_security_group_traffic == true
  ]))
  rules_from = flatten([
    for k1, v1 in var.network_security_groups : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : [
          for v4 in v3.source : {
            rule    = format("%s_%s_%s-src", k1, k2, v3.priority)
            sources = lookup(local.snets_map, substr(v4, 5, -1), replace(v4, "cidr:", ""))
          }
        ]
      ]
    ]
  ])
  rules_from_map = { for v in local.rules_from : v.rule => v.sources... }
  rules_intra_obj = flatten([
    for k, v in local.snets_attach_nsg : {
      rule    = v.nsg
      sources = data.azurerm_subnet.snet[v.snet].address_prefix
    }
  ])
  rules_intra_map = { for v in local.rules_intra_obj : v.rule => v.sources... }
  rules_map       = merge(local.rules_from_map, local.rules_to_map)
  rules_to = flatten([
    for k1, v1 in var.network_security_groups : [
      for k2, v2 in v1.rules : [
        for k3, v3 in v2 : [
          for v4 in v3.destination : {
            rule    = format("%s_%s_%s-dst", k1, k2, v3.priority)
            sources = lookup(local.snets_map, substr(v4, 5, -1), replace(v4, "cidr:", ""))
          }
        ]
      ]
    ]
  ])
  rules_to_map = { for v in local.rules_to : v.rule => v.sources... }
  snets_attach = toset(flatten([
    for k1, v1 in var.network_security_groups : [
      for v2 in v1.subnets : [format("%s/%s/%s", v1.resource_group, v1.virtual_network, v2)]
    ]
  ]))
  snets_attach_nsg = toset(flatten([
    for k1, v1 in var.network_security_groups : [
      for v2 in v1.subnets : {
        nsg  = k1
        snet = format("%s/%s/%s", v1.resource_group, v1.virtual_network, v2)
      }
    ]
  ]))
  snets_from = toset(flatten([
    for k1, v1 in var.network_security_groups : [
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
    for k1, v1 in var.network_security_groups : [
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
    for k1, v1 in var.network_security_groups : [
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
    for k1, v1 in var.network_security_groups : [
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
  for_each = setunion(local.rgs_from, local.rgs_home, local.rgs_to)

  name = each.value
}

data "azurerm_subnet" "snet" {
  for_each = setunion(local.snets_attach, local.snets_from, local.snets_to)

  resource_group_name  = split("/", each.value)[0]
  name                 = split("/", each.value)[2]
  virtual_network_name = split("/", each.value)[1]
}

data "azurerm_virtual_network" "vnet" {
  for_each = setunion(local.vnets_from, local.vnets_to)

  resource_group_name = split("/", each.value)[0]
  name                = split("/", each.value)[1]
}

resource "azurerm_network_security_group" "nsg" {
  for_each = var.network_security_groups

  name                = each.key
  location            = data.azurerm_resource_group.rg[each.value.resource_group].location
  resource_group_name = data.azurerm_resource_group.rg[each.value.resource_group].name

  tags = merge(
    {
      terraform_managed = "true"
    },
    each.value.tags
  )
}

resource "azurerm_network_security_rule" "nsgr-deny_implicit" {
  for_each = { for k, v in var.network_security_groups : k => v if v.deny_implicit_traffic == true }

  resource_group_name         = each.value.resource_group
  name                        = "deny implicit traffic"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = each.key
}

resource "azurerm_network_security_rule" "nsgr-intra" {
  for_each = { for k, v in local.rules_intra : format("%s_intra", v.nsg) => v }

  resource_group_name          = each.value.resource_group
  name                         = each.value.description
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.from_port
  destination_port_range       = each.value.to_port
  source_address_prefixes      = each.value.source
  destination_address_prefixes = each.value.destination
  network_security_group_name  = each.value.nsg
}

resource "azurerm_network_security_rule" "nsgr-custom" {
  for_each = { for k, v in local.rules_custom : format("%s_%s_%s", v.nsg, v.direction, v.priority) => v }

  resource_group_name          = each.value.resource_group
  name                         = each.value.description
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.from_port[0] == "*" ? "*" : null
  source_port_ranges           = each.value.from_port[0] != "*" ? each.value.from_port : null
  destination_port_range       = each.value.to_port[0] == "*" ? "*" : null
  destination_port_ranges      = each.value.to_port[0] != "*" ? each.value.to_port : null
  source_address_prefix        = each.value.source[0] == "*" ? "*" : null
  source_address_prefixes      = each.value.source[0] != "*" ? each.value.source : null
  destination_address_prefix   = each.value.destination[0] == "*" ? "*" : null
  destination_address_prefixes = each.value.destination[0] != "*" ? each.value.destination : null
  network_security_group_name  = each.value.nsg
}

resource "azurerm_subnet_network_security_group_association" "nsga" {
  for_each = { for k, v in local.snets_attach_nsg : format("%s_%s", v.snet, v.nsg) => v }

  subnet_id                 = data.azurerm_subnet.snet[each.value.snet].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg].id
}