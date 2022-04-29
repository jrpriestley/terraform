module "resource_group" {

  resource_groups = {
    rg-tf-primary-01 = {
      location = "East US"
      tags = {
      }
    }
    rg-tf-secondary-01 = {
      location = "West US"
      tags = {
      }
    }
  }

  providers = {
    azurerm = azurerm.azure-01
  }

  # do not edit this block
  source = "../../modules/resource_group"

}

module "virtual_network" {

  depends_on = [
    module.resource_group,
  ]

  virtual_networks = {
    vnet-tf-primary-01 = {
      resource_group = "rg-tf-primary-01"
      cidrs          = ["10.10.0.0/16"]
      tags = {
      }
    }
    vnet-tf-secondary-01 = {
      resource_group = "rg-tf-secondary-01"
      cidrs          = ["10.20.0.0/16"]
      tags = {
      }
    }
  }

  providers = {
    azurerm = azurerm.azure-01
  }

  # do not edit this block
  source = "../../modules/virtual_network"

}

module "subnet" {

  depends_on = [
    module.virtual_network,
  ]

  subnets = {
    vnet-tf-primary-01 = {
      resource_group = "rg-tf-primary-01"
      subnets = {
        public-01  = ["10.10.0.0/24"]
        private-01 = ["10.10.64.0/24"]
      }
    }
    vnet-tf-secondary-01 = {
      resource_group = "rg-tf-secondary-01"
      subnets = {
        public-01  = ["10.20.0.0/24"]
        private-01 = ["10.20.64.0/24"]
      }
    }
  }

  providers = {
    azurerm = azurerm.azure-01
  }

  # do not edit this block
  source = "../../modules/subnet"

}

module "network_security_group" {

  /*
  
  The structure of network_security_groups is as follows:

    nsg = {                                                     # NSG name, e.g., nsg-01
      resource_group  = "rg"                                    # the resource group to store the NSG
      virtual_network = "vnet"                                  # the virtual network holding the subnet(s) to be attached to the NSG
      subnets         = ["subnet1", "subnet2", "subnet3", ...]  # list of subnet(s) to attach the NSG to
      rules = {
        ingress = [                                             # list of ingress (Inbound in Azure terms) rules; specify [] if no entries are required
          {
            description = "allow SSH"
            priority    = 100
            access      = "allow"                               # allow or deny
            protocol    = "tcp"                                 # protocol or * for any
            from_port   = ["*"]                                 # list of source ports; specifying "*" will cause additional entries to be ignored
            to_port     = ["22"]                                # list of destination ports; specifying "*" will cause additional entries to be ignored
            source      = ["cidr:1.1.1.1/32"]                   # list of mixed cidr:0.0.0.0/0 or snet:rg/vnet/snet naming; specifying snet: will use dynamic lookup of the subnet (even those outside of Terraform) and convert to CIDR
            destination = ["snet:rg/vnet/public"]               # list of mixed cidr:0.0.0.0/0 or snet:rg/vnet/snet naming; specifying snet: will use dynamic lookup of the subnet (even those outside of Terraform) and convert to CIDR
          },
        ],
        egress = []                                             # list of egress (Outbound in Azure terms) rules; specify [] if no entries are required
      }
      tags = {
      }
    }
  
  */

  depends_on = [
    module.resource_group,
    module.subnet,
    module.virtual_network,
  ]

  network_security_groups = {
    nsg-tf-primary-01-public-01 = {
      resource_group                    = "rg-tf-primary-01"
      virtual_network                   = "vnet-tf-primary-01"
      subnets                           = ["public-01"]
      allow_same_security_group_traffic = true
      deny_implicit_traffic             = true
      rules = {
        ingress = [
          {
            description = "allow RDP from Lumen resources"
            priority    = 200
            access      = "allow"
            protocol    = "tcp"
            from_port   = ["*"]
            to_port     = ["3389"]
            source      = ["cidr:174.119.103.254/32"]
            destination = ["snet:rg-tf-primary-01/vnet-tf-primary-01/public-01"]
          },
        ]
      }
      tags = {
      }
    }
    nsg-tf-primary-01-private-01 = {
      resource_group                    = "rg-tf-primary-01"
      virtual_network                   = "vnet-tf-primary-01"
      subnets                           = ["private-01"]
      allow_same_security_group_traffic = true
      deny_implicit_traffic             = true
      rules = {
        ingress = [
          {
            description = "allow all from trusted subnets"
            priority    = 200
            access      = "allow"
            protocol    = "*"
            from_port   = ["*"]
            to_port     = ["*"]
            source      = ["snet:rg-tf-primary-01/vnet-tf-primary-01/public-01", "snet:rg-tf-secondary-01/vnet-tf-secondary-01/private-01"]
            destination = ["snet:rg-tf-primary-01/vnet-tf-primary-01/private-01"]
          },
        ]
      }
      tags = {
      }
    }
    nsg-tf-secondary-01-private-01 = {
      resource_group                    = "rg-tf-secondary-01"
      virtual_network                   = "vnet-tf-secondary-01"
      subnets                           = ["private-01"]
      allow_same_security_group_traffic = true
      deny_implicit_traffic             = true
      rules = {
        ingress = [
          {
            description = "allow all from trusted subnets"
            priority    = 200
            access      = "allow"
            protocol    = "*"
            from_port   = ["*"]
            to_port     = ["*"]
            source      = ["snet:rg-tf-primary-01/vnet-tf-primary-01/public-01", "snet:rg-tf-primary-01/vnet-tf-primary-01/private-01"]
            destination = ["snet:rg-tf-secondary-01/vnet-tf-secondary-01/private-01"]
          },
        ]
      }
      tags = {
      }
    }
  }

  providers = {
    azurerm = azurerm.azure-01
  }

  # do not edit this block
  source = "../../modules/network_security_group"

}

module "peering" {

  depends_on = [
    module.virtual_network,
  ]

  peers = {
    vnet-tf-primary-01 = {
      resource_group = "rg-tf-primary-01"
      peers          = ["vnet-tf-secondary-01"]
    }
    vnet-tf-secondary-01 = {
      resource_group = "rg-tf-secondary-01"
      peers          = ["vnet-tf-primary-01"]
    }
  }

  providers = {
    azurerm = azurerm.azure-01
  }

  # do not edit this block
  source = "../../modules/peering"

}

module "public_ip" {

  depends_on = [
    module.resource_group,
  ]

  public_ips = {
    pip-vm-tf-mgmt-01 = {
      resource_group    = "rg-tf-primary-01"
      allocation_method = "static"
      sku               = "standard"
      tags = {
      }
    }
  }

  providers = {
    azurerm = azurerm.azure-01
  }

  # do not edit this block
  source = "../../modules/public_ip"

}

module "windows_virtual_machine" {

  depends_on = [
    module.public_ip,
    module.subnet,
  ]

  virtual_machines = {
    vm-tf-mgmt-01 = {
      resource_group = "rg-tf-primary-01"
      size           = "Standard_DS1_v2"
      image = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
      }
      username        = "admin-terraform"
      password        = var.windows_virtual_machine_password
      public_ip       = "pip-vm-tf-mgmt-01"
      subnet          = "public-01"
      virtual_network = "vnet-tf-primary-01"
      tags = {
      }
    }
    vm-tf-ad-01 = {
      resource_group = "rg-tf-primary-01"
      size           = "Standard_DS1_v2"
      image = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
      }
      username        = "admin-terraform"
      password        = var.windows_virtual_machine_password
      public_ip       = null
      subnet          = "private-01"
      virtual_network = "vnet-tf-primary-01"
      tags = {
      }
    }
    vm-tf-ad-02 = {
      resource_group = "rg-tf-secondary-01"
      size           = "Standard_DS1_v2"
      image = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
      }
      username        = "admin-terraform"
      password        = var.windows_virtual_machine_password
      public_ip       = null
      subnet          = "private-01"
      virtual_network = "vnet-tf-secondary-01"
      tags = {
      }
    }
    vm-tf-vm-01 = {
      resource_group = "rg-tf-primary-01"
      size           = "Standard_DS1_v2"
      image = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
      }
      username        = "admin-terraform"
      password        = var.windows_virtual_machine_password
      public_ip       = null
      subnet          = "private-01"
      virtual_network = "vnet-tf-primary-01"
      tags = {
      }
    }
    vm-tf-vm-02 = {
      resource_group = "rg-tf-secondary-01"
      size           = "Standard_DS1_v2"
      image = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
      }
      username        = "admin-terraform"
      password        = "Pa55word123!"
      public_ip       = null
      subnet          = "private-01"
      virtual_network = "vnet-tf-secondary-01"
      tags = {
      }
    }
  }

  providers = {
    azurerm = azurerm.azure-01
  }

  # do not edit this block
  source = "../../modules/windows_virtual_machine"

}