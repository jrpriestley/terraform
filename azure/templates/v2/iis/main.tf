module "resource_group" {
  resource_groups = [
    {
      name     = "rg-${var.project_name}-01"
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
      resource_group = "rg-${var.project_name}-01"
      cidrs          = ["10.10.0.0/16"]
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
        gateway-01 = ["10.10.254.0/24"]
        public-01  = ["10.10.0.0/24"]
        private-01 = ["10.10.64.0/24"]
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
      name                              = "nsg-${var.project_name}-01-gateway-01"
      resource_group                    = "rg-${var.project_name}-01"
      virtual_network                   = "vnet-${var.project_name}-01"
      subnets                           = ["gateway-01"]
      allow_same_security_group_traffic = true
      deny_implicit_traffic             = true
      tags = {
      }
    },
    {
      name                              = "nsg-${var.project_name}-01-private-01"
      resource_group                    = "rg-${var.project_name}-01"
      virtual_network                   = "vnet-${var.project_name}-01"
      subnets                           = ["private-01"]
      allow_same_security_group_traffic = true
      deny_implicit_traffic             = true
      tags = {
      }
    },
    {
      name                              = "nsg-${var.project_name}-01-public-01"
      resource_group                    = "rg-${var.project_name}-01"
      virtual_network                   = "vnet-${var.project_name}-01"
      subnets                           = ["public-01"]
      allow_same_security_group_traffic = true
      deny_implicit_traffic             = true
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
      security_group = "nsg-${var.project_name}-01-gateway-01"
      resource_group = "rg-${var.project_name}-01"
      rules = {
        ingress = [
          {
            description = "allow HTTP from any"
            priority    = 300
            access      = "allow"
            protocol    = "tcp"
            from_port   = ["*"]
            to_port     = ["80"]
            source      = ["Internet"]
            destination = ["VirtualNetwork"]
          },
          {
            description = "allow HTTPS from any"
            priority    = 400
            access      = "allow"
            protocol    = "tcp"
            from_port   = ["*"]
            to_port     = ["443"]
            source      = ["Internet"]
            destination = ["VirtualNetwork"]
          },
          {
            description = "allow application gateway ports from GatewayManager"
            priority    = 500
            access      = "allow"
            protocol    = "tcp"
            from_port   = ["*"]
            to_port     = ["65503-65534"]
            source      = ["GatewayManager"]
            destination = ["*"]
          },
        ]
      }
    },
    {
      security_group = "nsg-${var.project_name}-01-private-01"
      resource_group = "rg-${var.project_name}-01"
      rules = {
        ingress = [
          {
            description = "allow all from trusted subnets"
            priority    = 200
            access      = "allow"
            protocol    = "*"
            from_port   = ["*"]
            to_port     = ["*"]
            source      = ["snet:rg-${var.project_name}-01/vnet-${var.project_name}-01/public-01"]
            destination = ["VirtualNetwork"]
          },
          {
            description = "allow HTTP from gateway subnet"
            priority    = 300
            access      = "allow"
            protocol    = "tcp"
            from_port   = ["*"]
            to_port     = ["80"]
            source      = ["snet:rg-${var.project_name}-01/vnet-${var.project_name}-01/gateway-01"]
            destination = ["VirtualNetwork"]
          },
          {
            description = "allow HTTPS from gateway subnet"
            priority    = 400
            access      = "allow"
            protocol    = "tcp"
            from_port   = ["*"]
            to_port     = ["443"]
            source      = ["snet:rg-${var.project_name}-01/vnet-${var.project_name}-01/gateway-01"]
            destination = ["VirtualNetwork"]
          },
        ]
      }
    },
    {
      security_group = "nsg-${var.project_name}-01-public-01"
      resource_group = "rg-${var.project_name}-01"
      rules = {
        ingress = [
          {
            description = "allow any from Lumen resources"
            priority    = 300
            access      = "allow"
            protocol    = "tcp"
            from_port   = ["*"]
            to_port     = ["*"]
            source      = ["cidr:174.119.103.254/32"]
            destination = ["VirtualNetwork"]
          },
        ]
      }
    }
  ]

  source = "../../../modules/v2/network_security_group_rules"
}

module "public_ip" {
  depends_on = [
    module.resource_group,
  ]

  public_ips = [
    {
      name              = "pip-${var.project_name}-mgmt-01"
      resource_group    = "rg-${var.project_name}-01"
      allocation_method = "static"
      sku               = "standard"
      tags = {
      }
    },
    {
      name              = "pip-${var.project_name}-agw-01"
      resource_group    = "rg-${var.project_name}-01"
      allocation_method = "dynamic"
      sku               = "basic"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/public_ip"
}

module "windows_virtual_machine" {
  depends_on = [
    module.public_ip,
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
      username        = "admin-terraform"
      password        = var.windows_virtual_machine_password
      public_ip       = "pip-${var.project_name}-mgmt-01"
      subnet          = "public-01"
      virtual_network = "vnet-${var.project_name}-01"
      tags = {
      }
    },
    {
      name           = "vm-${var.project_name}-02"
      resource_group = "rg-${var.project_name}-01"
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
      virtual_network = "vnet-${var.project_name}-01"
      tags = {
      }
    },
    {
      name           = "vm-${var.project_name}-03"
      resource_group = "rg-${var.project_name}-01"
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
      virtual_network = "vnet-${var.project_name}-01"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/windows_virtual_machine"
}

module "application_gateway" {
  depends_on = [
    module.public_ip,
    module.resource_group,
    module.subnet,
    module.windows_virtual_machine,
  ]

  name           = "agw-${var.project_name}-01"
  resource_group = "rg-${var.project_name}-01"
  subnet         = "rg-${var.project_name}-01/vnet-${var.project_name}-01/gateway-01" # resource group/virtual network/subnet
  frontend = {
    ip       = "pip-${var.project_name}-agw-01"
    port     = 80
    protocol = "http"
  }
  backend = {
    members               = ["rg-${var.project_name}-01/vm-${var.project_name}-02", "rg-${var.project_name}-01/vm-${var.project_name}-03"]
    cookie_based_affinity = "disabled"
    port                  = 80
    protocol              = "http"
    request_timeout       = 60
  }
  sku = {
    name     = "Standard_Small" # Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, WAF_v2
    tier     = "Standard"       # Standard, Standard_v2, WAF, WAF_v2
    capacity = 2
  }
  tags = {
  }

  source = "../../../modules/v2/application_gateway"
}