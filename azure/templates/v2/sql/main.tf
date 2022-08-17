module "resource_group" {
  resource_groups = [
    {
      name     = "rg-${var.project_name}"
      location = "East US"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/resource_group"
}

module "virtual_network" {
  depends_on = [
    module.resource_group,
  ]

  virtual_networks = [
    {
      name           = "vnet-${var.project_name}-01"
      resource_group = "rg-${var.project_name}"
      location       = "eastus"
      cidrs          = ["10.64.0.0/16"]
      tags = {
      }
    },
    {
      name           = "vnet-${var.project_name}-02"
      resource_group = "rg-${var.project_name}"
      location       = "westus3"
      cidrs          = ["10.65.0.0/16"]
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/virtual_network"
}

module "subnet" {
  depends_on = [
    module.virtual_network,
  ]

  subnets = [
    {
      virtual_network = "vnet-${var.project_name}-01"
      resource_group  = "rg-${var.project_name}"
      subnets = {
        ad-01              = ["10.64.0.0/24"]
        sql-01             = ["10.64.1.0/24"]
        sql-02             = ["10.64.2.0/24"]
        AzureBastionSubnet = ["10.64.255.0/24"]
      }
    },
    {
      virtual_network = "vnet-${var.project_name}-02"
      resource_group  = "rg-${var.project_name}"
      subnets = {
        ad-01  = ["10.65.0.0/24"]
        sql-01 = ["10.65.1.0/24"]
        sql-02 = ["10.65.2.0/24"]
      }
    },
  ]

  source = "../../../modules/v2/subnet"
}

module "peering" {
  depends_on = [
    module.virtual_network,
  ]

  peerings = [
    {
      bidirectional_peering = true
      use_remote_gateway    = false
      src                   = ["rg-${var.project_name}/vnet-${var.project_name}-01"]
      dst                   = ["rg-${var.project_name}/vnet-${var.project_name}-02"]
    },
  ]

  providers = {
    azurerm.src = azurerm
    azurerm.dst = azurerm
  }

  source = "../../../modules/v2/peering"
}

module "windows_virtual_machine" {
  depends_on = [
    module.subnet,
  ]

  virtual_machines = [
    {
      name           = "vm-${var.project_name}-ad-01"
      resource_group = "rg-${var.project_name}"
      location       = "eastus"
      size           = "Standard_DS1_v2"
      image = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
      }
      username  = "jp"
      password  = var.windows_virtual_machine_password
      public_ip = null
      subnet    = "rg-${var.project_name}/vnet-${var.project_name}-01/ad-01"
      tags = {
      }
    },
    {
      name           = "vm-${var.project_name}-ad-02"
      resource_group = "rg-${var.project_name}"
      location       = "westus3"
      size           = "Standard_DS1_v2"
      image = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
      }
      username  = "jp"
      password  = var.windows_virtual_machine_password
      public_ip = null
      subnet    = "rg-${var.project_name}/vnet-${var.project_name}-02/ad-01"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/windows_virtual_machine"
}