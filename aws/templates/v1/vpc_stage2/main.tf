module "auth" {
  name       = "james.priestley"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA7+IBjPoVoaSWRDpiGEl8NnFhVbs6f3F6wBRXxed4szO/BYR1x83sy29rwTjkIeZXymcnZx08JBD9aqa7DN2oNL6YlIZ+BRGxxeyhqJ+hnw+Lxqs1ind28Xp04WJmIw2G079pKovxorhvTHl/D9QBYABj8aFPAg0IrG79Zame5hkgsM2LF8qIEn0sdIjRUizgA+JruTBww6nM+/FY+IiF1eKUcEktI+OIrYIWxRKXgX6ugCg/9JsLi/V3ZJTkD1Uzp2RBK5xspGSsI3BNr2RoAko+X4L5JmHDz5uKwmoFkVjHcm+1/7ewim/d6yd+b5YJNOD79fwdBBGDZyERXBNZnQ== james.priestley"

  # do not edit this block
  source = "../../../modules/auth/"

}

module "instance_bastion" {

  /*

  Set the following to null if post-instantiation provisioning is not required:
    provision_connect
    provision_file
    provision_script

  */
  instances = {
    /*
    ssh-01 = {
      ami      = "amzn2-ami-kernel-5.10-hvm-2.0.20211201.0-x86_64-gp2"
      key_pair = module.auth.key_pair_id
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
      security_group   = "terraform-public"
      size             = "t2.micro"
      subnet           = "terraform-public-01"
      tags = {
      }
    },
*/
  }

  # do not edit this block
  source = "../../../modules/instance/"

}

module "instance_web" {

  # If defining a bastion in the same pass as any instances that rely on it for provisioning, ensure that the instance module names are included.
  depends_on = [
    module.instance_bastion,
  ]

  /*

  Set the following to null if post-instantiation provisioning is not required:
    provision_connect
    provision_file
    provision_script

  For the provision_file, use LF for Linux and CRLF for Windows.

  */
  instances = {
    /*
    web-01 = {
      ami      = "amzn2-ami-kernel-5.10-hvm-2.0.20211201.0-x86_64-gp2"
      key_pair = module.auth.key_pair_id
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
      security_group   = "terraform-private"
      size             = "t2.micro"
      subnet           = "terraform-private-01"
      tags = {
        terraform_target_group_group1 = "true"
        terraform_target_group_group2 = "true"
      }
    },
    web-02 = {
      ami      = "amzn2-ami-kernel-5.10-hvm-2.0.20211201.0-x86_64-gp2"
      key_pair = module.auth.key_pair_id
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
      security_group   = "terraform-private"
      size             = "t2.micro"
      subnet           = "terraform-private-02"
      tags = {
        terraform_target_group_group1 = "true"
        terraform_target_group_group2 = "true"
      }
    },
    web-03 = {
      ami      = "amzn2-ami-kernel-5.10-hvm-2.0.20211201.0-x86_64-gp2"
      key_pair = module.auth.key_pair_id
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
      security_group   = "terraform-private"
      size             = "t2.micro"
      subnet           = "terraform-private-01"
      tags = {
        terraform_target_group_group1 = "true"
        terraform_target_group_group2 = "true"
      }
    },
    web-04 = {
      ami      = "amzn2-ami-kernel-5.10-hvm-2.0.20211201.0-x86_64-gp2"
      key_pair = module.auth.key_pair_id
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
      security_group   = "terraform-private"
      size             = "t2.micro"
      subnet           = "terraform-private-02"
      tags = {
        terraform_target_group_group1 = "true"
        terraform_target_group_group2 = "true"
      }
    },
*/
  }

  # do not edit this block
  source = "../../../modules/instance/"

}