data "azurerm_public_ip" "pip" {
  resource_group_name = var.resource_group
  name                = var.frontend.ip
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group
}

data "azurerm_subnet" "snet" {
  resource_group_name  = split("/", var.subnet)[0]
  name                 = split("/", var.subnet)[2]
  virtual_network_name = split("/", var.subnet)[1]
}

data "azurerm_virtual_machine" "vm" {
  for_each = toset(var.backend.members)

  resource_group_name = split("/", each.value)[0]
  name                = split("/", each.value)[1]
}

resource "azurerm_application_gateway" "agw" {
  name                = var.name
  resource_group_name = var.resource_group
  location            = data.azurerm_resource_group.rg.location

  backend_address_pool {
    name         = format("%s-bep-01", var.name)
    ip_addresses = [for k, v in data.azurerm_virtual_machine.vm : v.private_ip_address]
  }

  backend_http_settings {
    name                  = format("%s-behs-01", var.name)
    cookie_based_affinity = try(title(var.backend.cookie_based_affinity), "Disabled")
    path                  = try(var.backend.path, null)
    port                  = try(var.backend.port, 80)
    protocol              = try(title(var.backend.protocol), "Http")
    request_timeout       = try(var.backend.request_timeout, 60)
  }

  frontend_ip_configuration {
    name                 = format("%s-feipc-01", var.name)
    public_ip_address_id = data.azurerm_public_ip.pip.id
  }

  frontend_port {
    name = format("%s-fep-01", var.name)
    port = var.frontend.port
  }

  gateway_ip_configuration {
    name      = format("%s-ipc-01", var.name)
    subnet_id = data.azurerm_subnet.snet.id
  }

  http_listener {
    name                           = format("%s-%s-01", var.name, var.frontend.protocol)
    frontend_ip_configuration_name = format("%s-feipc-01", var.name)
    frontend_port_name             = format("%s-fep-01", var.name)
    protocol                       = title(var.frontend.protocol)
  }

  request_routing_rule {
    name                       = format("%s-rrr-01", var.name)
    rule_type                  = "Basic"
    http_listener_name         = format("%s-%s-01", var.name, var.frontend.protocol)
    backend_address_pool_name  = format("%s-bep-01", var.name)
    backend_http_settings_name = format("%s-behs-01", var.name)
  }

  sku {
    name     = try(var.sku.name, "Standard_Small")
    tier     = try(var.sku.tier, "Standard")
    capacity = try(var.sku.capacity, 2)
  }

  lifecycle {
    ignore_changes = [
      autoscale_configuration,
      backend_address_pool,
      backend_http_settings,
      frontend_ip_configuration,
      frontend_port,
      gateway_ip_configuration,
      http_listener,
      location,
      probe,
      redirect_configuration,
      request_routing_rule,
      url_path_map,
      ssl_certificate,
    ]
  }
}