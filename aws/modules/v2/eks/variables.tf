variable "create_iam_role" {
  type        = bool
  description = "Specify true if you want to create an IAM role specific to the cluster"
  default     = true
}

variable "create_security_group" {
  type        = bool
  description = "Specify true if you want to create a security group specific to the cluster"
  default     = true
}

variable "endpoint_private_access" {
  type        = bool
  description = "Specify true if you want to enable private access to the cluster"
  default     = true
}

variable "endpoint_public_access" {
  type        = bool
  description = "Specify true if you want to enable public access to the cluster"
  default     = true
}

variable "fargate_enabled" {
  type        = bool
  description = "Specify true if you want to enable FarGate profiles"
  default     = true
}

variable "name" {
  type        = string
  description = "Cluster name"
}

variable "node_groups" {
  type = list(object(
    {
      create_security_group = bool
      desired_size          = number
      key_pair              = string
      max_size              = number
      max_unavailable       = number
      min_size              = number
      name                  = string
      subnets               = list(string)
      tags                  = map(string)
    }
  ))
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "CIDRs with public access to the cluster"
}

variable "service_cidr" {
  type        = string
  description = "CIDR to use for cluster services (should be outside of VPC ranges)"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets (names) to attach the cluster to"
}

variable "tags" {
  type = map(string)
}

variable "vpc" {
  type        = string
  description = "VPC for the cluster to reside in"
}