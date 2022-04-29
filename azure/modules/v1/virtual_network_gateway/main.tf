data "azurerm_public_ip" "pip" {
  for_each = { for k, v in var.virtual_network_gateways : v.public_ip => v }

  resource_group_name = each.value.resource_group
  name                = each.key
}

data "azurerm_resource_group" "rg" {
  for_each = toset([for k, v in var.virtual_network_gateways : v.resource_group])

  name = each.value
}

data "azurerm_subnet" "snet" {
  for_each = { for k, v in var.virtual_network_gateways : format("%s_%s", v.virtual_network, v.subnet) => v }

  resource_group_name  = each.value.resource_group
  name                 = each.value.subnet
  virtual_network_name = each.value.virtual_network
}

resource "azurerm_virtual_network_gateway" "vng-wo-conn-01" {
  for_each = var.virtual_network_gateways

  name                = each.key
  resource_group_name = each.value.resource_group
  location            = data.azurerm_resource_group.rg[each.value.resource_group].location

  type          = each.value.type
  vpn_type      = each.value.vpn_type
  active_active = each.value.active_active
  enable_bgp    = each.value.enable_bgp
  sku           = title(each.value.sku)

  ip_configuration {
    name                          = format("ipc-%s-01", each.key)
    subnet_id                     = data.azurerm_subnet.snet[format("%s_%s", each.value.virtual_network, each.value.subnet)].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = data.azurerm_public_ip.pip[each.value.public_ip].id
  }

  tags = merge(
    {
      terraform_managed = "true"
    },
    each.value.tags
  )
}