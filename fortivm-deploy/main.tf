# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.47.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

# Create Resource group
resource "azurerm_resource_group" "RG-01" {
  name = var.resource_group_name_01
  location = var.region_name
}

# Create VNet and Subnets
resource "azurerm_virtual_network" "VNET-01" {
  name = var.vnet_01
  location = var.region_name
  address_space = var.vnet_01_address_space
  resource_group_name = azurerm_resource_group.RG-01.name

  subnet {
    name = var.subnet_name_01
    address_prefix = var.subnet_01_address_prefix
  }
  subnet {
    name = var.subnet_name_02
    address_prefix = var.subnet_02_address_prefix
  }
}