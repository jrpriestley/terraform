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