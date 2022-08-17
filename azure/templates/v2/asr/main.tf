module "resource_group" {
  resource_groups = [
    {
      name     = "rg-${var.project_name}-01"
      location = "East US"
      tags = {
      }
    },
    {
      name     = "rg-${var.project_name}-02"
      location = "West US"
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
      resource_group = "rg-${var.project_name}-01"
      cidrs          = ["10.201.0.0/16"]
      tags = {
      }
    },
    {
      name           = "vnet-${var.project_name}-02"
      resource_group = "rg-${var.project_name}-02"
      cidrs          = ["10.202.0.0/16"]
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
      resource_group  = "rg-${var.project_name}-01"
      subnets = {
        private-01 = ["10.201.64.0/24"]
      }
    },
    {
      virtual_network = "vnet-${var.project_name}-02"
      resource_group  = "rg-${var.project_name}-02"
      subnets = {
        private-01 = ["10.202.64.0/24"]
      }
    },
  ]

  source = "../../../modules/v2/subnet"
}

module "network_security_group" {
  depends_on = [
    module.resource_group,
    module.subnet,
    module.virtual_network,
  ]

  network_security_groups = [
    {
      name                   = "nsg-${var.project_name}-01-private-01"
      resource_group         = "rg-${var.project_name}-01"
      virtual_network        = "vnet-${var.project_name}-01"
      subnets                = ["private-01"]
      allow_intra_inbound    = true
      allow_intra_outbound   = false
      deny_implicit_inbound  = true
      deny_implicit_outbound = false
      tags = {
      }
    },
    {
      name                   = "nsg-${var.project_name}-02-private-01"
      resource_group         = "rg-${var.project_name}-02"
      virtual_network        = "vnet-${var.project_name}-02"
      subnets                = ["private-01"]
      allow_intra_inbound    = true
      allow_intra_outbound   = false
      deny_implicit_inbound  = true
      deny_implicit_outbound = false
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/network_security_group"
}

module "network_security_group_rules" {
  depends_on = [
    module.network_security_group,
    module.resource_group,
    module.subnet,
    module.virtual_network,
  ]

  network_security_group_rules = [
    {
      security_group = "nsg-${var.project_name}-01-private-01"
      resource_group = "rg-${var.project_name}-01"
      rules = {
        ingress = [
          {
            description = "allow any from Lumen resources"
            priority    = 200
            access      = "allow"
            protocol    = "tcp"
            from_port   = ["*"]
            to_port     = ["*"]
            source      = ["cidr:174.119.103.254/32"]
            destination = ["VirtualNetwork"]
          },
        ]
      }
    },
    {
      security_group = "nsg-${var.project_name}-02-private-01"
      resource_group = "rg-${var.project_name}-02"
      rules = {
        ingress = [
          {
            description = "allow any from Lumen resources"
            priority    = 200
            access      = "allow"
            protocol    = "tcp"
            from_port   = ["*"]
            to_port     = ["*"]
            source      = ["cidr:174.119.103.254/32"]
            destination = ["VirtualNetwork"]
          },
        ]
      }
    },
  ]

  source = "../../../modules/v2/network_security_group_rules"
}

module "windows_virtual_machine" {
  depends_on = [
    module.subnet,
  ]

  virtual_machines = [
    {
      name           = "vm-${var.project_name}-01"
      resource_group = "rg-${var.project_name}-01"
      size           = "Standard_DS1_v2"
      image = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
      }
      username  = "admin-terraform"
      password  = var.windows_virtual_machine_password
      public_ip = null
      subnet    = "rg-${var.project_name}-01/vnet-${var.project_name}-01/private-01"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/windows_virtual_machine"
}