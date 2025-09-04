terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.34.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = ""
    storage_account_name = ""
    container_name       = ""
    key                  = ""
  }
 }

provider "azurerm" {
  features {}
  subscription_id = "ff1f4c30-e1a5-4c53-ad94-da022a3f2ca1"
}



