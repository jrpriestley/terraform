module "vpc_spoke-01" {
  name          = "spoke-01"
  cidr          = "10.1.0.0/16"
  create_igw    = false
  dns_hostnames = true
  dns_support   = true
  tags = {
  }

  source = "../../../modules/v2/vpc"
}

module "vpc_hub" {
  name          = "hub"
  cidr          = "10.255.0.0/16"
  create_igw    = true
  dns_hostnames = true
  dns_support   = true
  tags = {
  }

  source = "../../../modules/v2/vpc"
}

module "subnet_spoke-01" {
  depends_on = [
    module.vpc_spoke-01,
  ]

  subnets = [
    {
      name                    = "spoke-01-private-01-${var.region}a"
      availability_zone       = "${var.region}a"
      cidr                    = "10.1.64.0/24"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "spoke-01-private-02-${var.region}b"
      availability_zone       = "${var.region}b"
      cidr                    = "10.1.65.0/24"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "spoke-01-public-01-${var.region}a"
      availability_zone       = "${var.region}a"
      cidr                    = "10.1.0.0/24"
      create_ngw              = false
      map_public_ip_on_launch = true
      tags = {
      }
    },
    {
      name                    = "spoke-01-public-02-${var.region}b"
      availability_zone       = "${var.region}b"
      cidr                    = "10.1.1.0/24"
      create_ngw              = false
      map_public_ip_on_launch = true
      tags = {
      }
    },
    {
      name                    = "spoke-01-tgw-01-${var.region}a"
      availability_zone       = "${var.region}a"
      cidr                    = "10.1.128.0/28"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "spoke-01-tgw-02-${var.region}b"
      availability_zone       = "${var.region}b"
      cidr                    = "10.1.129.0/28"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "spoke-01-gwlb-01-${var.region}a"
      availability_zone       = "${var.region}a"
      cidr                    = "10.1.128.16/28"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "spoke-01-gwlb-02-${var.region}b"
      availability_zone       = "${var.region}b"
      cidr                    = "10.1.129.16/28"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/subnet"
  vpc    = "spoke-01"
}

module "subnet_hub" {
  depends_on = [
    module.vpc_hub,
  ]

  subnets = [
    {
      name                    = "hub-private-01-${var.region}a"
      availability_zone       = "${var.region}a"
      cidr                    = "10.255.64.0/24"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "hub-private-02-${var.region}b"
      availability_zone       = "${var.region}b"
      cidr                    = "10.255.65.0/24"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "hub-public-01-${var.region}a"
      availability_zone       = "${var.region}a"
      cidr                    = "10.255.0.0/24"
      create_ngw              = false
      map_public_ip_on_launch = true
      tags = {
      }
    },
    {
      name                    = "hub-public-02-${var.region}b"
      availability_zone       = "${var.region}b"
      cidr                    = "10.255.1.0/24"
      create_ngw              = false
      map_public_ip_on_launch = true
      tags = {
      }
    },
    {
      name                    = "hub-tgw-01-${var.region}a"
      availability_zone       = "${var.region}a"
      cidr                    = "10.255.128.0/28"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "hub-tgw-02-${var.region}b"
      availability_zone       = "${var.region}b"
      cidr                    = "10.255.129.0/28"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "hub-gwlb-01-${var.region}a"
      availability_zone       = "${var.region}a"
      cidr                    = "10.255.128.16/28"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "hub-gwlb-02-${var.region}b"
      availability_zone       = "${var.region}b"
      cidr                    = "10.255.129.16/28"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "hub-mgmt-01-${var.region}a"
      availability_zone       = "${var.region}a"
      cidr                    = "10.255.128.32/28"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "hub-mgmt-02-${var.region}b"
      availability_zone       = "${var.region}b"
      cidr                    = "10.255.129.32/28"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "hub-data-01-${var.region}a"
      availability_zone       = "${var.region}a"
      cidr                    = "10.255.128.48/28"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "hub-data-02-${var.region}b"
      availability_zone       = "${var.region}b"
      cidr                    = "10.255.129.48/28"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "hub-ngw-01-${var.region}a"
      availability_zone       = "${var.region}a"
      cidr                    = "10.255.128.64/28"
      create_ngw              = true
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "hub-ngw-02-${var.region}b"
      availability_zone       = "${var.region}b"
      cidr                    = "10.255.129.64/28"
      create_ngw              = true
      map_public_ip_on_launch = false
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/subnet"
  vpc    = "hub"
}

module "route_table_spoke-01" {
  depends_on = [
    module.subnet_spoke-01,
  ]

  route_tables = [
    {
      name = "spoke-01-private-01-${var.region}a"
      routes = {
      }
      subnets = ["spoke-01-private-01-${var.region}a"]
      tags = {
      }
    },
    {
      name = "spoke-01-private-02-${var.region}b"
      routes = {
      }
      subnets = ["spoke-01-private-02-${var.region}b"]
      tags = {
      }
    },
    {
      name = "spoke-01-public-01-${var.region}a"
      routes = {
      }
      subnets = ["spoke-01-public-01-${var.region}a"]
      tags = {
      }
    },
    {
      name = "spoke-01-public-02-${var.region}b"
      routes = {
      }
      subnets = ["spoke-01-public-02-${var.region}b"]
      tags = {
      }
    },
    {
      name = "spoke-01-gwlb-01-${var.region}a"
      routes = {
      }
      subnets = ["spoke-01-gwlb-01-${var.region}a"]
      tags = {
      }
    },
    {
      name = "spoke-01-gwlb-02-${var.region}b"
      routes = {
      }
      subnets = ["spoke-01-gwlb-02-${var.region}b"]
      tags = {
      }
    },
    {
      name = "spoke-01-igw-01-${var.region}a"
      routes = {
      }
      subnets = []
      tags = {
      }
    },
    {
      name = "spoke-01-igw-02-${var.region}b"
      routes = {
      }
      subnets = []
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/route_table"
  vpc    = "spoke-01"
}

module "route_table_hub" {
  depends_on = [
    module.subnet_hub,
  ]

  route_tables = [
    {
      name = "hub-private-01-${var.region}a"
      routes = {
      }
      subnets = ["hub-private-01-${var.region}a"]
      tags = {
      }
    },
    {
      name = "hub-private-02-${var.region}b"
      routes = {
      }
      subnets = ["hub-private-02-${var.region}b"]
      tags = {
      }
    },
    {
      name = "hub-public-01-${var.region}a"
      routes = {
      }
      subnets = ["hub-public-01-${var.region}a"]
      tags = {
      }
    },
    {
      name = "hub-public-02-${var.region}b"
      routes = {
      }
      subnets = ["hub-public-02-${var.region}b"]
      tags = {
      }
    },
    {
      name = "hub-tgw-01-${var.region}a"
      routes = {
      }
      subnets = ["hub-tgw-01-${var.region}a"]
      tags = {
      }
    },
    {
      name = "hub-tgw-02-${var.region}b"
      routes = {
      }
      subnets = ["hub-tgw-02-${var.region}b"]
      tags = {
      }
    },
    {
      name = "hub-gwlb-01-${var.region}a"
      routes = {
      }
      subnets = ["hub-gwlb-01-${var.region}a"]
      tags = {
      }
    },
    {
      name = "hub-gwlb-02-${var.region}b"
      routes = {
      }
      subnets = ["hub-gwlb-02-${var.region}b"]
      tags = {
      }
    },
    {
      name = "hub-data-01-${var.region}a"
      routes = {
      }
      subnets = ["hub-data-01-${var.region}a"]
      tags = {
      }
    },
    {
      name = "hub-data-02-${var.region}b"
      routes = {
      }
      subnets = ["hub-mgmt-02-${var.region}b"]
      tags = {
      }
    },
    {
      name = "hub-mgmt-01-${var.region}a"
      routes = {
        "0.0.0.0/0" = "igw:hub",
      }
      subnets = ["hub-mgmt-01-${var.region}a"]
      tags = {
      }
    },
    {
      name = "hub-mgmt-02-${var.region}b"
      routes = {
        "0.0.0.0/0" = "igw:hub",
      }
      subnets = ["hub-mgmt-02-${var.region}b"]
      tags = {
      }
    },
    {
      name = "hub-ngw-01-${var.region}a"
      routes = {
      }
      subnets = ["hub-ngw-01-${var.region}a"]
      tags = {
      }
    },
    {
      name = "hub-ngw-02-${var.region}b"
      routes = {
      }
      subnets = ["hub-ngw-02-${var.region}b"]
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/route_table"
  vpc    = "hub"
}

module "security_group_spoke-01" {
  depends_on = [
    module.vpc_spoke-01,
  ]

  security_groups = [
    {
      name                              = "spoke-01-private"
      allow_same_security_group_traffic = true
      tags = {
      }
    },
    {
      name                              = "spoke-01-public"
      allow_same_security_group_traffic = true
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/security_group"
  vpc    = "spoke-01"
}

module "security_group_hub" {
  depends_on = [
    module.vpc_hub,
  ]

  security_groups = [
    {
      name                              = "hub-private"
      allow_same_security_group_traffic = true
      tags = {
      }
    },
    {
      name                              = "hub-public"
      allow_same_security_group_traffic = true
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/security_group"
  vpc    = "hub"
}

module "security_group_rules_spoke-01" {
  depends_on = [
    module.security_group_spoke-01,
  ]

  security_group_rules = [
    {
      security_group = "spoke-01-private"
      ingress = [
        {
          description = "allow any from spoke-01-public security group"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["sg:spoke-01-public"]
        },
      ],
      egress = [
        {
          description = "allow any to any"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["cidr:0.0.0.0/0"]
        },
      ],
    },
    {
      security_group = "spoke-01-public"
      ingress = [
        {
          description = "allow any from spoke-01-private security group"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["sg:spoke-01-private"]
        },
      ],
      egress = [
        {
          description = "allow any to any"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["cidr:0.0.0.0/0"]
        },
      ],
    },
  ]

  source = "../../../modules/v2/security_group_rule"
  vpc    = "spoke-01"
}

module "security_group_rules_hub" {
  depends_on = [
    module.security_group_hub,
  ]

  security_group_rules = [
    {
      security_group = "hub-private"
      ingress = [
        {
          description = "allow any from hub-public security group"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["sg:hub-public"]
        },
        {
          description = "allow any from Lumen resources"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["cidr:174.119.103.254/32"]
        },
      ],
      egress = [
        {
          description = "allow any to any"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["cidr:0.0.0.0/0"]
        },
      ],
    },
    {
      security_group = "hub-public"
      ingress = [
        {
          description = "allow any from hub-private security group"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["sg:hub-private"]
        },
      ],
      egress = [
        {
          description = "allow any to any"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["cidr:0.0.0.0/0"]
        },
      ],
    },
  ]

  source = "../../../modules/v2/security_group_rule"
  vpc    = "hub"
}