variable "clusters" {
  type = map(object(
    {
      create_iam_role         = bool
      create_security_group   = bool
      endpoint_private_access = bool
      endpoint_public_access  = bool
      node_groups = map(object(
        {
          create_security_group = bool
          desired_size          = number
          key_pair              = string
          max_size              = number
          max_unavailable       = number
          min_size              = number
          subnets               = list(string)
          tags                  = map(string)
        }
      ))
      public_access_cidrs = list(string)
      service_cidr        = string
      subnets             = list(string)
      tags                = map(string)
    }
  ))
}

variable "repositories" {
  type = map(object(
    {
      remote_cidr = string
      tags        = map(string)
    }
  ))
}

variable "vpc" {
  type = string
}