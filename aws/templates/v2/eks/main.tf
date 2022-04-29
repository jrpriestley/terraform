module "vpc" {
  name          = var.vpc
  cidr          = var.cidr
  create_igw    = true
  dns_hostnames = true
  dns_support   = true
  tags = {
  }

  source = "../../../modules/v2/vpc"
}

module "subnet" {
  depends_on = [
    module.vpc,
  ]

  subnets = [
    {
      name                    = "${var.vpc}-private-01"
      availability_zone       = "us-east-1a"
      cidr                    = "10.10.64.0/24"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "${var.vpc}-private-02"
      availability_zone       = "us-east-1b"
      cidr                    = "10.10.65.0/24"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "${var.vpc}-public-01"
      availability_zone       = "us-east-1a"
      cidr                    = "10.10.0.0/24"
      create_ngw              = true
      map_public_ip_on_launch = true
      tags = {
      }
    },
    {
      name                    = "${var.vpc}-public-02"
      availability_zone       = "us-east-1b"
      cidr                    = "10.10.1.0/24"
      create_ngw              = true
      map_public_ip_on_launch = true
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/subnet"
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

  source = "../../../modules/v2/route_table"
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

  source = "../../../modules/v2/security_group"
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
          description = "allow all from ${var.vpc}-public security group"
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
          description = "allow all from ${var.vpc}-private security group"
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

  source = "../../../modules/v2/security_group_rule"
  vpc    = var.vpc
}

module "eks" {
  depends_on = [
    module.subnet,
  ]

  name                    = "cluster-01"
  create_iam_role         = true
  create_security_group   = true
  endpoint_private_access = true
  endpoint_public_access  = true
  fargate_enabled         = true
  public_access_cidrs     = ["0.0.0.0/0"]
  service_cidr            = "10.20.0.0/16"
  subnets                 = ["${var.vpc}-private-01", "${var.vpc}-private-02"]
  node_groups = [
    {
      name                  = "system"
      create_security_group = true
      desired_size          = 2
      key_pair              = "james.priestley"
      max_size              = 4
      max_unavailable       = 1
      min_size              = 1
      subnets               = ["${var.vpc}-private-01", "${var.vpc}-private-02"]
      tags = {
      }
    }
  ]
  tags = {
  }

  source = "../../../modules/v2/eks"
  vpc    = var.vpc
}

module "ecr" {
  depends_on = [
    module.vpc,
  ]

  name                = "ecr-01"
  public_access_cidrs = ["174.119.103.254/32"]
  tags = {
  }

  # do not edit this block
  source = "../../../modules/v2/ecr"

}

/*
module "instance-bastion" {
  depends_on = [
    module.security_group,
    module.subnet,
  ]

  instances = [
    {
      name      = "${var.vpc}-ssh-01"
      ami_name  = "RHEL-8.*x86_64*"
      ami_owner = "309956199498"
      key_pair  = "james.priestley"
      provision_connect = {
        host             = "self"
        host_private_key = "./etc/files/id_rsa.secret"
        host_user        = "ec2-user"
      }
      provision_file = {
        source      = "./etc/files/"
        destination = "/tmp/"
      }
      provision_script = "./etc/scripts/configure.sh"
      security_group   = "${var.vpc}-public"
      size             = "t2.micro"
      subnet           = "${var.vpc}-public-01"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/instance_provisioned/"
  vpc    = var.vpc
}

module "instance-backend" {
  depends_on = [
    module.instance-bastion,
    module.security_group,
    module.subnet,
  ]

  instances = [
    {
      name      = "${var.vpc}-backend-01"
      ami_name  = "RHEL-8.*x86_64*"
      ami_owner = "309956199498"
      key_pair  = "james.priestley"
      provision_connect = {
        host             = "${var.vpc}-ssh-01"
        host_private_key = "./etc/files/id_rsa.secret"
        host_user        = "ec2-user"
      }
      provision_file = {
        source      = "./etc/files/"
        destination = "/tmp/"
      }
      provision_script = "./etc/scripts/configure.sh"
      security_group   = "${var.vpc}-private"
      size             = "t2.large"
      subnet           = "${var.vpc}-private-01"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/instance_provisioned/"
  vpc    = var.vpc
}
*/