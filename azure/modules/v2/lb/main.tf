locals {
  addresses = toset(flatten([
    for k1, v1 in var.backend_address_pools : [
      for k2, v2 in v1.addresses : {
        ip_address = v2.ip_address
        name       = v2.name
        pool       = azurerm_lb_backend_address_pool.lb_pool[v1.name].id
        vnet       = data.azurerm_virtual_network.vnet[v2.vnet].id
      }
    ]
  ]))
  rgs = toset(flatten([
    for k1, v1 in var.backend_address_pools : [
      for k2, v2 in v1.addresses : [split("/", v2.vnet)[0]]
    ]
  ]))
  vnets = toset(flatten([
    for k1, v1 in var.backend_address_pools : [
      for k2, v2 in v1.addresses : [v2.vnet]
    ]
  ]))
}

data "azurerm_public_ip" "pip" {
  count = var.frontend_ip_configuration.public_ip != null ? 1 : 0

  resource_group_name = var.resource_group
  name                = var.frontend_ip_configuration.public_ip
}

data "azurerm_resource_group" "rg" {
  for_each = setunion([var.resource_group], local.rgs)

  name = each.value
}

data "azurerm_subnet" "snet" {
  count = var.frontend_ip_configuration.subnet != null ? 1 : 0

  resource_group_name  = split("/", var.frontend_ip_configuration.subnet)[0]
  name                 = split("/", var.frontend_ip_configuration.subnet)[2]
  virtual_network_name = split("/", var.frontend_ip_configuration.subnet)[1]
}

data "azurerm_virtual_network" "vnet" {
  for_each = local.vnets

  name                = split("/", each.value)[1]
  resource_group_name = data.azurerm_resource_group.rg[split("/", each.value)[0]].name
}

resource "azurerm_lb" "lb" {
  location            = data.azurerm_resource_group.rg[var.resource_group].location
  name                = var.name
  resource_group_name = data.azurerm_resource_group.rg[var.resource_group].name
  sku                 = title(var.sku)

  frontend_ip_configuration {
    name                          = "fe-01"
    availability_zone             = var.frontend_ip_configuration.availability_zone != null ? replace(var.frontend_ip_configuration.availability_zone, "no-zone", "No-Zone") : null
    public_ip_address_id          = var.frontend_ip_configuration.public_ip != null ? data.azurerm_public_ip.pip[0].id : null
    private_ip_address_allocation = var.frontend_ip_configuration.private_ip_address_allocation
    private_ip_address_version    = var.frontend_ip_configuration.private_ip_address_version != null ? replace(var.frontend_ip_configuration.private_ip_address_version, "ipv4", "IPv4") : null
    subnet_id                     = var.frontend_ip_configuration.subnet != null ? data.azurerm_subnet.snet[0].id : null
  }

  tags = merge(
    {
      terraform_managed = "true"
    },
    var.tags
  )

}

resource "azurerm_lb_backend_address_pool" "lb_pool" {
  for_each = { for k, v in var.backend_address_pools : v.name => v }

  name            = each.key
  loadbalancer_id = azurerm_lb.lb.id
}

/*
resource "azurerm_lb_backend_address_pool_address" "lb_pool_address" {
  for_each = { for k, v in local.addresses : v.name => v }

  name                    = each.key
  backend_address_pool_id = each.value.pool
  virtual_network_id      = each.value.vnet
  ip_address              = each.value.ip_address
}
*/