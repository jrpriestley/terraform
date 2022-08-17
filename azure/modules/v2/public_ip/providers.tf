terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  experiments      = [module_variable_optional_attrs]
  required_version = ">= 1.1.0"
}