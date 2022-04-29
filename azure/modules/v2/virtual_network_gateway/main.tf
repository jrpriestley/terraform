data "azurerm_public_ip" "pip" {
  resource_group_name = var.resource_group
  name                = var.public_ip
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group
}

data "azurerm_subnet" "snet" {
  resource_group_name  = var.resource_group
  name                 = var.subnet
  virtual_network_name = var.virtual_network
}

resource "azurerm_virtual_network_gateway" "vng-wo-conn-01" {
  name                = var.name
  resource_group_name = var.resource_group
  location            = data.azurerm_resource_group.rg.location

  type          = var.type
  vpn_type      = var.vpn_type
  active_active = var.active_active
  enable_bgp    = var.enable_bgp
  sku           = title(var.sku)

  ip_configuration {
    name                          = format("ipc-%s-01", var.name)
    subnet_id                     = data.azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = data.azurerm_public_ip.pip.id
  }

  tags = merge(
    {
      terraform_managed = "true"
    },
    var.tags
  )
}