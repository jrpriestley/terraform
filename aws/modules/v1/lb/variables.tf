variable "load_balancers" {
  type = map(object(
    {
      add_lb_security_group_rules = bool
      internal                    = bool
      load_balancer_type          = string
      security_group              = string
      subnets                     = list(string)
      listeners = list(object(
        {
          port         = number
          protocol     = string
          target_group = string
        }
      ))
      tags = map(string)
    },
  ))
}

variable "target_groups" {
  type = map(object(
    {
      add_instance_security_group_rules = bool
      instance_tag_prefix               = string
      port                              = number
      protocol                          = string
    }
  ))
}

variable "vpc" {
  type = string
}