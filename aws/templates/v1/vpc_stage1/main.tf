module "subnet" {
  subnets = {
    terraform-private-01 = {
      availability_zone       = "us-east-1a"
      cidr                    = "10.0.64.0/24"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    terraform-private-02 = {
      availability_zone       = "us-east-1b"
      cidr                    = "10.0.65.0/24"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    terraform-public-01 = {
      availability_zone       = "us-east-1a"
      cidr                    = "10.0.0.0/24"
      create_ngw              = true
      map_public_ip_on_launch = true
      tags = {
      }
    },
    terraform-public-02 = {
      availability_zone       = "us-east-1b"
      cidr                    = "10.0.1.0/24"
      create_ngw              = true
      map_public_ip_on_launch = true
      tags = {
      }
    },
  }

  # do not edit this block
  source = "../../../modules/subnet"
  vpc    = var.vpc

}

module "route_table" {

  # If defining route tables in the same pass as subnets, ensure that the subnet module names are included.
  depends_on = [
    module.subnet,
  ]

  /*

  routes values are one of:
    igw:name    igw:terraform
    ngw:name    ngw:terraform-public-01

  */
  route_tables = {
    terraform-private-01 = {
      routes = {
        "0.0.0.0/0" = "ngw:terraform-public-01"
      }
      subnets = ["terraform-private-01"]
      tags = {
      }
    },
    terraform-private-02 = {
      routes = {
        "0.0.0.0/0" = "ngw:terraform-public-02"
      }
      subnets = ["terraform-private-02"]
      tags = {
      }
    },
    terraform-public = {
      routes = {
        "0.0.0.0/0" = "igw:terraform"
      }
      subnets = ["terraform-public-01", "terraform-public-02"]
      tags = {
      }
    },
  }

  # do not edit this block
  source = "../../../modules/route_table"
  vpc    = var.vpc

}

module "security_group" {
  security_groups = {
    terraform-private = {
      allow_same_security_group_traffic = true
      tags = {
      }
    },
    terraform-public = {
      allow_same_security_group_traffic = true
      tags = {
      }
    },
  }

  # do not edit this block
  source = "../../../modules/security_group"
  vpc    = var.vpc

}

module "security_group_rules" {

  # If defining security group rules in the same pass as security groups, ensure that the security group rule module names are included.
  depends_on = [
    module.security_group,
  ]

  # Terraform appears to have an issue whereby security group rules cannot be found during modify. The workaround is to remove the rule (comment out), apply, uncomment the updated rule, and apply again.

  /*

  endpoints values are one of:
    cidr:cidr   e.g., cidr:10.0.0.0/24
    sg:name     e.g., sg:terraform-public

  */
  security_group_rules = {
    terraform-private = {
      ingress = [
        {
          description = "allow any from public security group"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["sg:terraform-public"]
        },
        /*
        {
          description = "allow RDP from public security group"
          from_port   = 3389
          to_port     = 3389
          protocol    = "tcp"
          endpoints   = ["sg:terraform-public"]
        },
        {
          description = "allow SSH from public security group"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          endpoints   = ["sg:terraform-public"]
        },
*/
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
    terraform-public = {
      ingress = [
        {
          description = "allow any from private security group"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["sg:terraform-private"]
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
  }

  # do not edit this block
  source = "../../../modules/security_group_rule"
  vpc    = var.vpc

}