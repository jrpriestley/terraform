variable "region" {
  type        = string
  description = "The AWS region to deploy to, e.g., us-east-1"
}

variable "vpc" {
  type        = string
  description = "The name of the VPC to deploy to"
}