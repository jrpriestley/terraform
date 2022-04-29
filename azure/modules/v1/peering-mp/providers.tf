terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 2.65"
      configuration_aliases = [azurerm.dst, azurerm.src]
    }
  }

  required_version = ">= 1.1.0"
}