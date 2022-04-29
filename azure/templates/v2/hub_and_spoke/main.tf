module "resource_group" {
  resource_groups = [
    {
      name     = "rg-${var.project_name}-hub-01"
      location = "East US"
      tags = {
      }
    },
    {
      name     = "rg-${var.project_name}-spoke-01"
      location = "East US"
      tags = {
      }
    }
  ]

  source = "../../../modules/v2/resource_group"
}

module "virtual_network" {
  depends_on = [
    module.resource_group,
  ]

  virtual_networks = [
    {
      name           = "vnet-${var.project_name}-hub-01"
      resource_group = "rg-${var.project_name}-hub-01"
      cidrs          = ["10.255.0.0/16"]
      tags = {
      }
    },
    {
      name           = "vnet-${var.project_name}-spoke-01"
      resource_group = "rg-${var.project_name}-spoke-01"
      cidrs          = ["10.10.0.0/16"]
      tags = {
      }
    }
  ]

  source = "../../../modules/v2/virtual_network"
}

module "subnet" {
  depends_on = [
    module.virtual_network,
  ]

  subnets = [
    {
      virtual_network = "vnet-${var.project_name}-hub-01"
      resource_group  = "rg-${var.project_name}-hub-01"
      subnets = {
        public-01           = ["10.255.0.0/24"]
        private-01          = ["10.255.64.0/24"]
        AzureFirewallSubnet = ["10.255.255.0/24"]
      }
    },
    {
      virtual_network = "vnet-${var.project_name}-spoke-01"
      resource_group  = "rg-${var.project_name}-spoke-01"
      subnets = {
        public-01  = ["10.10.0.0/24"]
        private-01 = ["10.10.64.0/24"]
      }
    }
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
      name                              = "nsg-${var.project_name}-hub-01-private-01"
      resource_group                    = "rg-${var.project_name}-hub-01"
      virtual_network                   = "vnet-${var.project_name}-hub-01"
      subnets                           = ["private-01"]
      allow_same_security_group_traffic = true
      deny_implicit_traffic             = true
      tags = {
      }
    },
    {
      name                              = "nsg-${var.project_name}-hub-01-public-01"
      resource_group                    = "rg-${var.project_name}-hub-01"
      virtual_network                   = "vnet-${var.project_name}-hub-01"
      subnets                           = ["public-01"]
      allow_same_security_group_traffic = true
      deny_implicit_traffic             = true
      tags = {
      }
    },
    {
      name                              = "nsg-${var.project_name}-spoke-01-private-01"
      resource_group                    = "rg-${var.project_name}-spoke-01"
      virtual_network                   = "vnet-${var.project_name}-spoke-01"
      subnets                           = ["private-01"]
      allow_same_security_group_traffic = true
      deny_implicit_traffic             = true
      tags = {
      }
    },
    {
      name                              = "nsg-${var.project_name}-spoke-01-public-01"
      resource_group                    = "rg-${var.project_name}-spoke-01"
      virtual_network                   = "vnet-${var.project_name}-spoke-01"
      subnets                           = ["public-01"]
      allow_same_security_group_traffic = true
      deny_implicit_traffic             = true
      tags = {
      }
    }
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
      security_group = "nsg-${var.project_name}-hub-01-public-01"
      resource_group = "rg-${var.project_name}-hub-01"
      rules = {
        ingress = [
          {
            description = "allow any from trusted subnets"
            priority    = 200
            access      = "allow"
            protocol    = "*"
            from_port   = ["*"]
            to_port     = ["*"]
            source      = ["snet:rg-${var.project_name}-hub-01/vnet-${var.project_name}-hub-01/AzureFirewallSubnet"]
            destination = ["VirtualNetwork"]
          },
          {
            description = "allow any from Lumen resources"
            priority    = 300
            access      = "allow"
            protocol    = "*"
            from_port   = ["*"]
            to_port     = ["*"]
            source      = ["cidr:174.119.103.254/32"]
            destination = ["VirtualNetwork"]
          },
        ]
      }
    },
    {
      security_group = "nsg-${var.project_name}-spoke-01-private-01"
      resource_group = "rg-${var.project_name}-spoke-01"
      rules = {
        ingress = [
          {
            description = "allow any from trusted subnets"
            priority    = 200
            access      = "allow"
            protocol    = "*"
            from_port   = ["*"]
            to_port     = ["*"]
            source      = ["snet:rg-${var.project_name}-hub-01/vnet-${var.project_name}-hub-01/public-01"]
            destination = ["VirtualNetwork"]
          },
        ]
      }
    },
  ]

  source = "../../../modules/v2/network_security_group_rules"
}

module "peering" {
  depends_on = [
    module.resource_group,
    module.virtual_network,
  ]

  peerings = [
    {
      bidirectional_peering = true
      use_remote_gateway    = false
      src                   = ["rg-${var.project_name}-spoke-01/vnet-${var.project_name}-spoke-01"]
      dst                   = ["rg-${var.project_name}-hub-01/vnet-${var.project_name}-hub-01"]
    },
  ]

  providers = {
    azurerm.src = azurerm
    azurerm.dst = azurerm
  }

  source = "../../../modules/v2/peering"
}

module "public_ip" {
  depends_on = [
    module.resource_group,
  ]

  public_ips = [
    {
      name              = "pip-afw-${var.project_name}-01-01"
      resource_group    = "rg-${var.project_name}-hub-01"
      allocation_method = "static"
      sku               = "standard"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/public_ip"
}

/*
module "firewall" {
  depends_on = [
    module.public_ip,
    module.subnet,
  ]

  firewalls = [
    {
      name = "afw-${var.project_name}-01"
      resource_group  = "rg-${var.project_name}-hub-01"
      public_ip       = "pip-agw-${var.project_name}-01-01"
      subnet          = "AzureFirewallSubnet"
      virtual_network = "vnet-${var.project_name}-hub-01"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/firewall"
}
*/

module "key" {
  depends_on = [
    module.resource_group,
  ]

  keys = [
    {
      name           = "key-${var.project_name}-azure-terraform"
      resource_group = "rg-${var.project_name}-hub-01"
      public_key     = "./etc/azure-terraform.pub"
      tags = {
      }
    }
  ]

  source = "../../../modules/v2/key"
}

module "linux_virtual_machine" {
  depends_on = [
    module.public_ip,
    module.subnet,
  ]

  virtual_machines = [
    {
      name           = "vm-${var.project_name}-hub-01"
      resource_group = "rg-${var.project_name}-hub-01"
      size           = "Standard_DS1_v2"
      image = {
        publisher = "Debian"
        offer     = "debian-11"
        sku       = "11"
        version   = "latest"
      }
      username        = "admin-terraform"
      public_key      = "./etc/azure-terraform.pub"
      public_ip       = null
      subnet          = "public-01"
      virtual_network = "vnet-${var.project_name}-hub-01"
      tags = {
      }
    },
    {
      name           = "vm-${var.project_name}-spoke-01"
      resource_group = "rg-${var.project_name}-spoke-01"
      size           = "Standard_DS1_v2"
      image = {
        publisher = "Debian"
        offer     = "debian-11"
        sku       = "11"
        version   = "latest"
      }
      username        = "admin-terraform"
      public_key      = "./etc/azure-terraform.pub"
      public_ip       = null
      subnet          = "private-01"
      virtual_network = "vnet-${var.project_name}-spoke-01"
      tags = {
      }
    }
  ]

  source = "../../../modules/v2/linux_virtual_machine"
}