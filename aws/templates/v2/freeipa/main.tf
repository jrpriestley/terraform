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

module "instance-bastion" {
  depends_on = [
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

module "instance-hosts" {
  depends_on = [
    module.instance-bastion,
    module.subnet,
  ]

  instances = [
    {
      name      = "${var.vpc}-host-01"
      ami_name  = "RHEL-8.*x86_64*"
      ami_owner = "309956199498"
      key_pair  = "james.priestley"
      provision_connect = {
        host             = "${var.vpc}-ssh-01"
        host_private_key = "./etc/private/id_rsa"
        host_user        = "ec2-user"
      }
      provision_file = {
        source      = "./etc/private/"
        destination = "/home/ec2-user/.ssh/"
      }
      provision_script = "./etc/scripts/configure-master.sh"
      security_group   = "${var.vpc}-private"
      size             = "t3.large"
      subnet           = "${var.vpc}-private-01"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/instance_provisioned/"
  vpc    = var.vpc
}

module "instance-mgmt" {
  depends_on = [
    module.subnet,
  ]

  instances = [
    {
      name           = "${var.vpc}-mgmt-01"
      ami_name       = "Windows_Server-2019-English-Full-Base*"
      ami_owner      = "amazon"
      key_pair       = "james.priestley"
      security_group = "${var.vpc}-public"
      size           = "t2.micro"
      subnet         = "${var.vpc}-public-01"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/instance/"
  vpc    = var.vpc
}

module "instance-clients" {
  depends_on = [
    module.instance-bastion,
    module.subnet,
  ]

  instances = [
    {
      name      = "${var.vpc}-client-01"
      ami_name  = "RHEL-8.*x86_64*"
      ami_owner = "309956199498"
      key_pair  = "james.priestley"
      provision_connect = {
        host             = "${var.vpc}-ssh-01"
        host_private_key = "./etc/private/id_rsa"
        host_user        = "ec2-user"
      }
      provision_file = {
        source      = "./etc/private/"
        destination = "/home/ec2-user/.ssh/"
      }
      provision_script = "./etc/scripts/configure-client.sh"
      security_group   = "${var.vpc}-private"
      size             = "t2.micro"
      subnet           = "${var.vpc}-private-01"
      tags = {
      }
    },
    {
      name      = "${var.vpc}-client-02"
      ami_name  = "RHEL-8.*x86_64*"
      ami_owner = "309956199498"
      key_pair  = "james.priestley"
      provision_connect = {
        host             = "${var.vpc}-ssh-01"
        host_private_key = "./etc/private/id_rsa"
        host_user        = "ec2-user"
      }
      provision_file = {
        source      = "./etc/private/"
        destination = "/home/ec2-user/.ssh/"
      }
      provision_script = "./etc/scripts/configure-client.sh"
      security_group   = "${var.vpc}-private"
      size             = "t2.micro"
      subnet           = "${var.vpc}-private-02"
      tags = {
      }
    },
  ]

  source = "../../../modules/v2/instance_provisioned/"
  vpc    = var.vpc
}

module "route53-forward" {
  depends_on = [
    module.instance-clients,
    module.instance-hosts,
    module.vpc,
  ]

  name = var.route_53_domain

  records = [
    {
      name    = "_kerberos.${var.route_53_domain}"
      type    = "txt"
      ttl     = 300
      records = ["${var.route_53_domain}"]
    },
    {
      name    = "_kerberos-master._tcp.${var.route_53_domain}"
      type    = "srv"
      ttl     = 300
      records = ["0 100 88 ipa.${var.route_53_domain}."]
    },
    {
      name    = "_kerberos-master._udp.${var.route_53_domain}"
      type    = "srv"
      ttl     = 300
      records = ["0 100 88 ipa.${var.route_53_domain}."]
    },
    {
      name    = "_kerberos._tcp.${var.route_53_domain}"
      type    = "srv"
      ttl     = 300
      records = ["0 100 88 ipa.${var.route_53_domain}."]
    },
    {
      name    = "_kerberos._udp.${var.route_53_domain}"
      type    = "srv"
      ttl     = 300
      records = ["0 100 88 ipa.${var.route_53_domain}."]
    },
    {
      name    = "_kpasswd._tcp.${var.route_53_domain}"
      type    = "srv"
      ttl     = 300
      records = ["0 100 464 ipa.${var.route_53_domain}."]
    },
    {
      name    = "_kpasswd._udp.${var.route_53_domain}"
      type    = "srv"
      ttl     = 300
      records = ["0 100 464 ipa.${var.route_53_domain}."]
    },
    {
      name    = "_ldap._tcp.${var.route_53_domain}"
      type    = "srv"
      ttl     = 300
      records = ["0 100 389 ipa.${var.route_53_domain}."]
    },
    {
      name    = "ipa-ca.${var.route_53_domain}"
      type    = "a"
      ttl     = 300
      records = [module.instance-hosts.instances["${var.vpc}-host-01"].private_ip]
    },
    {
      name    = "ipa.${var.route_53_domain}"
      type    = "a"
      ttl     = 300
      records = [module.instance-hosts.instances["${var.vpc}-host-01"].private_ip]
    },
    {
      name    = "client-01.${var.route_53_domain}"
      type    = "a"
      ttl     = 300
      records = [module.instance-clients.instances["${var.vpc}-client-01"].private_ip]
    },
    {
      name    = "client-02.${var.route_53_domain}"
      type    = "a"
      ttl     = 300
      records = [module.instance-clients.instances["${var.vpc}-client-02"].private_ip]
    },
  ]

  source = "../../../modules/v2/route53"
  vpc    = var.vpc
}