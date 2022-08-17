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

variable "vpc" {
  type        = string
  description = "The name of the VPC to deploy"
  default     = "hub-01"
}