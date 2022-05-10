locals {
  nsg_snets = toset(flatten([
    for k1, v1 in var.network_security_groups : [
      for v2 in v1.subnets : {
        nsg  = v1.name
        snet = format("%s/%s/%s", v1.resource_group, v1.virtual_network, v2)
      }
    ]
  ]))
  rules_intra_inbound = toset(flatten([
    for k, v in var.network_security_groups : {
      nsg            = v.name
      resource_group = v.resource_group
      name           = "allow any from intra inbound"
      priority       = 100
      direction      = "Inbound"
      access         = "Allow"
      protocol       = "*"
      from_port      = "*"
      to_port        = "*"
      source         = lookup(local.rules_intra_map, v.name)
      destination    = lookup(local.rules_intra_map, v.name)
    } if v.allow_intra_inbound == true
  ]))
  rules_intra_outbound = toset(flatten([
    for k, v in var.network_security_groups : {
      nsg            = v.name
      resource_group = v.resource_group
      name           = "allow any to intra outbound"
      priority       = 100
      direction      = "Outbound"
      access         = "Allow"
      protocol       = "*"
      from_port      = "*"
      to_port        = "*"
      source         = lookup(local.rules_intra_map, v.name)
      destination    = lookup(local.rules_intra_map, v.name)
    } if v.allow_intra_outbound == true
  ]))
  rules_intra_obj = flatten([
    for k, v in local.nsg_snets : {
      rule    = v.nsg
      sources = data.azurerm_subnet.snet[v.snet].address_prefix
    }
  ])
  rules_intra_map = { for v in local.rules_intra_obj : v.rule => v.sources... }
  snets = toset(flatten([
    for k1, v1 in var.network_security_groups : [
      for v2 in v1.subnets : [format("%s/%s/%s", v1.resource_group, v1.virtual_network, v2)]
    ]
  ]))
}

data "azurerm_resource_group" "rg" {
  for_each = toset(flatten([for k, v in var.network_security_groups : v.resource_group]))

  name = each.value
}

data "azurerm_subnet" "snet" {
  for_each = local.snets

  resource_group_name  = split("/", each.value)[0]
  name                 = split("/", each.value)[2]
  virtual_network_name = split("/", each.value)[1]
}

resource "azurerm_network_security_group" "nsg" {
  for_each = { for k, v in var.network_security_groups : v.name => v }

  name                = each.key
  resource_group_name = data.azurerm_resource_group.rg[each.value.resource_group].name
  location            = data.azurerm_resource_group.rg[each.value.resource_group].location

  tags = merge(
    {
      terraform_managed = "true"
    },
    each.value.tags
  )

  lifecycle {
    ignore_changes = [
      location,
    ]
  }
}

resource "azurerm_network_security_rule" "deny_implicit_inbound" {
  depends_on = [
    azurerm_network_security_group.nsg,
  ]

  for_each = { for k, v in var.network_security_groups : format("%s_deny_implicit_inbound", v.name) => v if v.deny_implicit_inbound == true }

  resource_group_name         = each.value.resource_group
  network_security_group_name = each.value.name
  name                        = "deny implicit traffic inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "deny_implicit_outbound" {
  depends_on = [
    azurerm_network_security_group.nsg,
  ]

  for_each = { for k, v in var.network_security_groups : format("%s_deny_implicit_outbound", v.name) => v if v.deny_implicit_outbound == true }

  resource_group_name         = each.value.resource_group
  network_security_group_name = each.value.name
  name                        = "deny implicit traffic outbound"
  priority                    = 4096
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "allow_intra_inbound" {
  depends_on = [
    azurerm_network_security_group.nsg,
  ]

  for_each = { for k, v in local.rules_intra_inbound : format("%s_allow_intra_inbound", v.nsg) => v }

  resource_group_name          = each.value.resource_group
  network_security_group_name  = each.value.nsg
  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.from_port
  destination_port_range       = each.value.to_port
  source_address_prefixes      = each.value.source
  destination_address_prefixes = each.value.destination
}

resource "azurerm_network_security_rule" "allow_intra_outbound" {
  depends_on = [
    azurerm_network_security_group.nsg,
  ]

  for_each = { for k, v in local.rules_intra_outbound : format("%s_allow_intra_outbound", v.nsg) => v }

  resource_group_name          = each.value.resource_group
  network_security_group_name  = each.value.nsg
  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.from_port
  destination_port_range       = each.value.to_port
  source_address_prefixes      = each.value.source
  destination_address_prefixes = each.value.destination
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  for_each = { for k, v in local.nsg_snets : format("%s_%s", v.snet, v.nsg) => v }

  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg].id
  subnet_id                 = data.azurerm_subnet.snet[each.value.snet].id

  lifecycle {
    ignore_changes = [
      network_security_group_id,
      subnet_id,
    ]
  }
}