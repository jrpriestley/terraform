variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc" {
  type        = string
  description = "The name of the VPC to deploy to"
}