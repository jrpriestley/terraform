variable "add_lb_security_group_rules" {
  type        = bool
  description = "Specify true if you want to adjust the security group assigned to the load balancer"
}

variable "internal" {
  type        = bool
  description = "Specify true for an internal load balancer or false for an external load balancer"
}

variable "load_balancer_type" {
  type        = string
  description = "Specify application, gateway, or network"
}

variable "name" {
  type        = string
  description = "Load balancer name"
}

variable "security_group" {
  type        = string
  description = "Security group to assign to the load balancer"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets to assign to the load balancer - must be multi-AZ"
}

variable "listeners" {
  type = list(object(
    {
      port         = number
      protocol     = string
      target_group = string
    }
  ))
  description = "Listeners to assign to the load balancer"
}

variable "tags" {
  type        = map(string)
  description = "Tags to assign to the load balancer"
}

variable "target_groups" {
  type = list(object(
    {
      add_instance_security_group_rules = bool
      instance_tag_prefix               = string
      name                              = string
      port                              = number
      protocol                          = string
    }
  ))
  description = "Target groups to assign to the load balancer"
}

variable "vpc" {
  type        = string
  description = "VPC for the load balancer to reside in"
}