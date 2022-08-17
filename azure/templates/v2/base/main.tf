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
      name                   = "nsg-${var.project_name}-01-private-01"
      resource_group         = "rg-${var.project_name}-01"
      virtual_network        = "vnet-${var.project_name}-01"
      subnets                = ["private-01"]
      allow_intra_inbound    = true
      allow_intra_outbound   = false
      deny_implicit_inbound  = false
      deny_implicit_outbound = false
      tags = {
      }
    },
    {
      name                   = "nsg-${var.project_name}-01-public-01"
      resource_group         = "rg-${var.project_name}-01"
      virtual_network        = "vnet-${var.project_name}-01"
      subnets                = ["public-01"]
      allow_intra_inbound    = true
      allow_intra_outbound   = false
      deny_implicit_inbound  = false
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
            description = "allow any from trusted subnets"
            priority    = 110
            access      = "allow"
            protocol    = "*"
            from_port   = ["*"]
            to_port     = ["*"]
            source      = ["snet:rg-${var.project_name}-01/vnet-${var.project_name}-01/public-01"]
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
            priority    = 110
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