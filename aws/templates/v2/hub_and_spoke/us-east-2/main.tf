module "vpc" {
  name          = var.vpc
  cidr          = var.cidr
  create_igw    = true
  dns_hostnames = true
  dns_support   = true
  tags = {
  }

  source = "../../../../modules/v2/vpc"
}

module "subnet" {
  depends_on = [
    module.vpc,
  ]

  subnets = [
    {
      name                    = "${var.vpc}-private-01"
      availability_zone       = "${var.region}a"
      cidr                    = cidrsubnet(var.cidr, 24 - split("/", var.cidr)[1], 64)
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "${var.vpc}-private-02"
      availability_zone       = "${var.region}b"
      cidr                    = cidrsubnet(var.cidr, 24 - split("/", var.cidr)[1], 65)
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "${var.vpc}-public-01"
      availability_zone       = "${var.region}a"
      cidr                    = cidrsubnet(var.cidr, 24 - split("/", var.cidr)[1], 0)
      create_ngw              = true
      map_public_ip_on_launch = true
      tags = {
      }
    },
    {
      name                    = "${var.vpc}-public-02"
      availability_zone       = "${var.region}b"
      cidr                    = cidrsubnet(var.cidr, 24 - split("/", var.cidr)[1], 1)
      create_ngw              = true
      map_public_ip_on_launch = true
      tags = {
      }
    },
  ]

  source = "../../../../modules/v2/subnet"
  vpc    = var.vpc
}

module "route_table" {
  depends_on = [
    module.subnet,
  ]

  route_tables = [
    {
      name = "${var.vpc}-private-01"
      routes = {
        "0.0.0.0/0" = "ngw:${var.vpc}-public-01"
      }
      subnets = ["${var.vpc}-private-01"]
      tags = {
      }
    },
    {
      name = "${var.vpc}-private-02"
      routes = {
        "0.0.0.0/0" = "ngw:${var.vpc}-public-02"
      }
      subnets = ["${var.vpc}-private-02"]
      tags = {
      }
    },
    {
      name = "${var.vpc}-public"
      routes = {
        "0.0.0.0/0" = "igw:${var.vpc}"
      }
      subnets = ["${var.vpc}-public-01", "${var.vpc}-public-02"]
      tags = {
      }
    },
  ]

  source = "../../../../modules/v2/route_table"
  vpc    = var.vpc
}

module "security_group" {
  depends_on = [
    module.vpc,
  ]

  security_groups = [
    {
      name                              = "${var.vpc}-private"
      allow_same_security_group_traffic = true
      tags = {
      }
    },
    {
      name                              = "${var.vpc}-public"
      allow_same_security_group_traffic = true
      tags = {
      }
    },
  ]

  source = "../../../../modules/v2/security_group"
  vpc    = var.vpc
}

module "security_group_rules" {
  depends_on = [
    module.security_group,
  ]

  security_group_rules = [
    {
      security_group = "${var.vpc}-private"
      ingress = [
        {
          description = "allow any from ${var.vpc}-public security group"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["sg:${var.vpc}-public"]
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
      security_group = "${var.vpc}-public"
      ingress = [
        {
          description = "allow any from ${var.vpc}-private security group"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["sg:${var.vpc}-private"]
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
  ]

  source = "../../../../modules/v2/security_group_rule"
  vpc    = var.vpc
}