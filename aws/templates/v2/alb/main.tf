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
      cidr                    = "10.20.64.0/24"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "${var.vpc}-private-02"
      availability_zone       = "us-east-1b"
      cidr                    = "10.20.65.0/24"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    {
      name                    = "${var.vpc}-public-01"
      availability_zone       = "us-east-1a"
      cidr                    = "10.20.0.0/24"
      create_ngw              = true
      map_public_ip_on_launch = true
      tags = {
      }
    },
    {
      name                    = "${var.vpc}-public-02"
      availability_zone       = "us-east-1b"
      cidr                    = "10.20.1.0/24"
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
          description = "allow all from eks-public security group"
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
      security_group = "${var.vpc}-private"
      ingress = [
        {
          description = "allow all from eks-private security group"
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

module "instance-bastion" {
  depends_on = [
    module.subnet,
  ]

  instances = [
    {
      name      = "${var.vpc}-ssh-01"
      ami_name  = "amzn2-ami-kernel-5.*-hvm-*-gp2"
      ami_owner = "amazon"
      key_pair  = "james.priestley"
      provision = true
      provision_connect = {
        host             = "self"
        host_private_key = "./etc/private/id_rsa"
        host_user        = "ec2-user"
      }
      provision_file = {
        source      = "./etc/private/"
        destination = "/home/ec2-user/.ssh/"
      }
      provision_script = "./etc/scripts/configure-bastion.sh"
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

module "instance-web" {
  depends_on = [
    module.instance-bastion,
    module.subnet,
  ]

  instances = [
    {
      name      = "${var.vpc}-web-01"
      ami_name  = "amzn2-ami-kernel-5.*-hvm-*-gp2"
      ami_owner = "amazon"
      key_pair  = "james.priestley"
      provision = true
      provision_connect = {
        host             = "ssh-01"
        host_private_key = "./etc/private/id_rsa"
        host_user        = "ec2-user"
      }
      provision_file = {
        source      = "./etc/private/"
        destination = "/home/ec2-user/.ssh/"
      }
      provision_script = "./etc/scripts/configure-web.sh"
      security_group   = "${var.vpc}-private"
      size             = "t3.large"
      subnet           = "${var.vpc}-private-01"
      tags = {
        tg_tg-01 = true
      }
    },
    {
      name      = "${var.vpc}-web-02"
      ami_name  = "amzn2-ami-kernel-5.*-hvm-*-gp2"
      ami_owner = "amazon"
      key_pair  = "james.priestley"
      provision = true
      provision_connect = {
        host             = "ssh-01"
        host_private_key = "./etc/private/id_rsa"
        host_user        = "ec2-user"
      }
      provision_file = {
        source      = "./etc/private/"
        destination = "/home/ec2-user/.ssh/"
      }
      provision_script = "./etc/scripts/configure-web.sh"
      security_group   = "${var.vpc}-private"
      size             = "t3.large"
      subnet           = "${var.vpc}-private-02"
      tags = {
        tg_tg-01 = true
      }
    },
  ]

  source = "../../../modules/v2/instance_provisioned/"
  vpc    = var.vpc
}

module "lb-01" {
  depends_on = [
    module.security_group
  ]

  name                        = "${var.vpc}-lb-01"
  add_lb_security_group_rules = true
  internal                    = false
  load_balancer_type          = "application"
  security_group              = "${var.vpc}-public"
  subnets                     = ["${var.vpc}-public-01", "${var.vpc}-public-02"]
  listeners = [
    {
      port         = 80
      protocol     = "HTTP"
      target_group = "tg-01"
    },
  ]
  tags = {
  }

  target_groups = [

    /*

    Instances will be added to target groups based on the tag defined by instance_tag_prefix, e.g.:
      instance tag: terraform_target_group_group1 = "true"
      instance_tag_prefix = "terraform_target_group_"
      The resource definition will then look for any instance with the tag 'terraform_target_group_group1' defined.

    */
    {
      name                              = "tg-01"
      add_instance_security_group_rules = true
      instance_tag_prefix               = "tg_"
      port                              = 80
      protocol                          = "HTTP"
    },
  ]

  source = "../../../modules/v2/lb/"
  vpc    = var.vpc
}