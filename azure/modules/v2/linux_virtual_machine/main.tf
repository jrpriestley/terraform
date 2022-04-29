locals {
  snets = toset(flatten([
    for v in var.virtual_machines : {
      resource_group  = v.resource_group
      subnet          = v.subnet
      virtual_network = v.virtual_network
    }
  ]))
}

data "azurerm_public_ip" "pip" {
  for_each = { for k, v in var.virtual_machines : v.public_ip => v if v.public_ip != null }

  resource_group_name = each.value.resource_group
  name                = each.key
}

data "azurerm_resource_group" "rg" {
  for_each = toset([for k, v in var.virtual_machines : v.resource_group])

  name = each.value
}

data "azurerm_subnet" "snet" {
  for_each = { for k, v in local.snets : format("%s_%s", v.virtual_network, v.subnet) => v }

  resource_group_name  = each.value.resource_group
  name                 = each.value.subnet
  virtual_network_name = each.value.virtual_network
}

resource "azurerm_network_interface" "nic" {
  for_each = { for k, v in var.virtual_machines : v.name => v }

  name                = format("%s-nic-01", each.key)
  resource_group_name = each.value.resource_group
  location            = data.azurerm_resource_group.rg[each.value.resource_group].location

  ip_configuration {
    name                          = format("ipc-%s-01", each.key)
    subnet_id                     = data.azurerm_subnet.snet[format("%s_%s", each.value.virtual_network, each.value.subnet)].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.value.public_ip == null ? null : data.azurerm_public_ip.pip[each.value.public_ip].id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = { for k, v in var.virtual_machines : v.name => v }

  name                = each.key
  resource_group_name = each.value.resource_group
  location            = data.azurerm_resource_group.rg[each.value.resource_group].location
  size                = each.value.size
  admin_username      = each.value.username
  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id,
  ]

  admin_ssh_key {
    username   = each.value.username
    public_key = file(each.value.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = each.value.image.publisher
    offer     = each.value.image.offer
    sku       = each.value.image.sku
    version   = each.value.image.version
  }

  tags = merge(
    {
      terraform_managed = "true"
    },
    each.value.tags
  )
}