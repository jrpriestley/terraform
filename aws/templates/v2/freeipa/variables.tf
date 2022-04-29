variable "region" {
  type        = string
  description = "The AWS region to deploy to, e.g., us-east-1"
  default     = "us-east-1"
}

variable "cidr" {
  type        = string
  description = "The CIDR block to use for the VPC, e.g., 10.10.0.0/16"
  default     = "10.10.0.0/16"
}

variable "route_53_domain" {
  type        = string
  description = "The domain name to provision in Route 53"
  default     = "private.jrpriestley.com"
}

variable "vpc" {
  type        = string
  description = "The name of the VPC to deploy"
  default     = "freeipa"
}