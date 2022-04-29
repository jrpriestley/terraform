module "vpc" {

  name          = var.vpc
  cidr          = var.cidr
  create_igw    = true
  dns_hostnames = true
  dns_support   = true

  tags = {
  }

  # do not edit this block
  source = "../../../modules/vpc"

}

module "subnet" {

  # If defining subnets in the same pass as VPCs, ensure that the VPC module names are included.
  depends_on = [
    module.vpc,
  ]

  subnets = {
    ansible-private-01 = {
      availability_zone       = "us-east-1a"
      cidr                    = "10.10.64.0/24"
      create_ngw              = false
      map_public_ip_on_launch = false
      tags = {
      }
    },
    ansible-public-01 = {
      availability_zone       = "us-east-1a"
      cidr                    = "10.10.0.0/24"
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
    igw:name    e.g., igw:terraform
    ngw:name    e.g., ngw:ansible-public-01

  */
  route_tables = {
    ansible-private = {
      routes = {
        "0.0.0.0/0" = "ngw:ansible-public-01"
      }
      subnets = ["ansible-private-01"]
      tags = {
      }
    },
    ansible-public = {
      routes = {
        "0.0.0.0/0" = "igw:ansible"
      }
      subnets = ["ansible-public-01"]
      tags = {
      }
    },
  }

  # do not edit this block
  source = "../../../modules/route_table"
  vpc    = var.vpc

}

module "security_group" {

  # If defining security groups in the same pass as VPCs, ensure that the VPC module names are included.
  depends_on = [
    module.vpc,
  ]

  security_groups = {
    ansible-private = {
      allow_same_security_group_traffic = true
      tags = {
      }
    },
    ansible-public = {
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
    sg:name     e.g., sg:ansible-public

  */
  security_group_rules = {
    ansible-private = {
      ingress = [
        {
          description = "allow all from ansible-public security group"
          from_port   = 0
          to_port     = 0
          protocol    = "all"
          endpoints   = ["sg:ansible-public"]
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
    ansible-public = {
      ingress = [
        {
          description = "allow SSH from Lumen resources"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
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

module "auth" {
  name       = "james.priestley"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA7+IBjPoVoaSWRDpiGEl8NnFhVbs6f3F6wBRXxed4szO/BYR1x83sy29rwTjkIeZXymcnZx08JBD9aqa7DN2oNL6YlIZ+BRGxxeyhqJ+hnw+Lxqs1ind28Xp04WJmIw2G079pKovxorhvTHl/D9QBYABj8aFPAg0IrG79Zame5hkgsM2LF8qIEn0sdIjRUizgA+JruTBww6nM+/FY+IiF1eKUcEktI+OIrYIWxRKXgX6ugCg/9JsLi/V3ZJTkD1Uzp2RBK5xspGSsI3BNr2RoAko+X4L5JmHDz5uKwmoFkVjHcm+1/7ewim/d6yd+b5YJNOD79fwdBBGDZyERXBNZnQ== james.priestley"

  # do not edit this block
  source = "../../../modules/auth/"

}

module "instance-bastion" {

  # If defining instances in the same pass as subnets, ensure that the subnet module names are included.
  depends_on = [
    module.subnet,
  ]

  /*

  Set the following to null if post-instantiation provisioning is not required:
    provision_connect
    provision_file
    provision_script

  For the provision_file, use LF for Linux and CRLF for Windows.

  */
  instances = {
    ssh-01 = {
      ami_name  = "amzn2-ami-kernel-5.*-hvm-*-gp2"
      ami_owner = "amazon"
      key_pair  = module.auth.key_pair_id
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
      security_group   = "ansible-public"
      size             = "t2.micro"
      subnet           = "ansible-public-01"
      tags = {
      }
    },
  }

  # do not edit this block
  source = "../../../modules/instance/"

}

module "instance-ansible_hosts" {

  # If defining instances in the same pass as subnets, ensure that the subnet module names are included.
  depends_on = [
    module.instance-bastion,
    module.subnet,
  ]

  /*

  Set the following to null if post-instantiation provisioning is not required:
    provision_connect
    provision_file
    provision_script

  For the provision_file, use LF for Linux and CRLF for Windows.

  */
  instances = {
    ansible-host-01 = {
      ami_name  = "amzn2-ami-kernel-5.*-hvm-*-gp2"
      ami_owner = "amazon"
      key_pair  = module.auth.key_pair_id
      provision_connect = {
        host             = "ssh-01"
        host_private_key = "./etc/private/id_rsa"
        host_user        = "ec2-user"
      }
      provision_file = {
        source      = "./etc/private/"
        destination = "/home/ec2-user/.ssh/"
      }
      provision_script = "./etc/scripts/configure-master.sh"
      security_group   = "ansible-private"
      size             = "t2.micro"
      subnet           = "ansible-private-01"
      tags = {
      }
    },
  }

  # do not edit this block
  source = "../../../modules/instance/"

}

module "instance-ansible_clients" {

  # If defining instances in the same pass as subnets, ensure that the subnet module names are included.
  depends_on = [
    module.instance-bastion,
    module.subnet,
  ]

  /*

  Set the following to null if post-instantiation provisioning is not required:
    provision_connect
    provision_file
    provision_script

  For the provision_file, use LF for Linux and CRLF for Windows.

  */
  instances = {
    ansible-client-01 = {
      ami_name  = "amzn2-ami-kernel-5.*-hvm-*-gp2"
      ami_owner = "amazon"
      key_pair  = module.auth.key_pair_id
      provision_connect = {
        host             = "ssh-01"
        host_private_key = "./etc/private/id_rsa"
        host_user        = "ec2-user"
      }
      provision_file = {
        source      = "./etc/private/"
        destination = "/home/ec2-user/.ssh/"
      }
      provision_script = null
      security_group   = "ansible-private"
      size             = "t2.micro"
      subnet           = "ansible-private-01"
      tags = {
      }
    },
    ansible-client-02 = {
      ami_name  = "amzn2-ami-kernel-5.*-hvm-*-gp2"
      ami_owner = "amazon"
      key_pair  = module.auth.key_pair_id
      provision_connect = {
        host             = "ssh-01"
        host_private_key = "./etc/private/id_rsa"
        host_user        = "ec2-user"
      }
      provision_file = {
        source      = "./etc/private/"
        destination = "/home/ec2-user/.ssh/"
      }
      provision_script = null
      security_group   = "ansible-private"
      size             = "t2.micro"
      subnet           = "ansible-private-01"
      tags = {
      }
    },
  }

  # do not edit this block
  source = "../../../modules/instance/"

}

module "ansible" {

  depends_on = [
    module.instance-ansible_clients,
    module.instance-ansible_hosts,
  ]

  bastion = {
    host             = "ssh-01"
    host_private_key = "./etc/private/id_rsa"
    host_user        = "ec2-user"
  }
  clients = [
    "ansible-client-01",
    "ansible-client-02",
    #    "ansible-client-03",
    #    "ansible-client-04",
  ]
  hosts = [
    "ansible-host-01",
  ]
  template = {
    in  = "./etc/ansible/hosts.tftpl"
    out = "./etc/ansible/hosts"
  }

  # do not edit this block
  source = "../../../modules/ansible/"

}