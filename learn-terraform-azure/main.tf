# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "australiaeast"
  tags = {
    Environment = "Terraform Getting Started"
    Team = "DevOps"
  }
}

# Create Primary vnet
resource "azurerm_virtual_network" "vnet-main" {
  name                = "myTFVnetMain"
  address_space       = ["10.0.0.0/24"]
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create seconday vnets
resource "azurerm_virtual_network" "vnet-01" {
  name                = "myTFVnet01"
  address_space       = ["10.0.1.0/24"]
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_virtual_network" "vnet-02" {
  name                = "myTFVnet02"
  address_space       = ["10.0.2.0/24"]
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.rg.name
}

# Peer Vnets
resource "azurerm_virtual_network_peering" "main01-01" {
  name = "Peer-${azurerm_virtual_network.vnet-main.name}-to-${azurerm_virtual_network.vnet-01.name}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-main.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-01.id
}
resource "azurerm_virtual_network_peering" "main01-02" {
  name = "Peer-${azurerm_virtual_network.vnet-01.name}-to-${azurerm_virtual_network.vnet-main.name}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-01.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-main.id
}
resource "azurerm_virtual_network_peering" "main02-01" {
  name = "Peer-${azurerm_virtual_network.vnet-main.name}-to-${azurerm_virtual_network.vnet-02.name}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-main.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-02.id
}
resource "azurerm_virtual_network_peering" "main02-02" {
  name = "Peer-${azurerm_virtual_network.vnet-02.name}-to-${azurerm_virtual_network.vnet-main.name}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-02.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-main.id
}