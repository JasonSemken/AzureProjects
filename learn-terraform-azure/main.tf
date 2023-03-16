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

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.region_name
  tags = {
    Environment = "Terraform Getting Started"
    Team = "DevOps"
  }
}

# Create Primary vnet
resource "azurerm_virtual_network" "vnet-main" {
  name                = var.vnet_name_1
  address_space       = ["10.0.0.0/22"]
  location            = var.region_name
  resource_group_name = azurerm_resource_group.rg.name

  subnet {
    name = var.subnet_name_1
    address_prefix = "10.0.0.0/24"
  }
  subnet {
    name = "GatewaySubnet"
    address_prefix = "10.0.1.0/24"
  }
}

# Create seconday vnets
resource "azurerm_virtual_network" "vnet-01" {
  name                = var.vnet_name_2
  address_space       = ["10.0.4.0/23"]
  location            = var.region_name
  resource_group_name = azurerm_resource_group.rg.name

  subnet {
    name = var.subnet_name_2
    address_prefix = "10.0.4.0/24"
  }
}

resource "azurerm_virtual_network" "vnet-02" {
  name                = var.vnet_name_3
  address_space       = ["10.0.6.0/23"]
  location            = var.region_name
  resource_group_name = azurerm_resource_group.rg.name

  subnet {
    name = var.subnet_name_3
    address_prefix = "10.0.6.0/24"
  }
}

# Peer Vnets
resource "azurerm_virtual_network_peering" "MainToVnet01" {
  name = "Peer-${azurerm_virtual_network.vnet-main.name}-to-${azurerm_virtual_network.vnet-01.name}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-main.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-01.id
}
resource "azurerm_virtual_network_peering" "MainFromVnet01" {
  name = "Peer-${azurerm_virtual_network.vnet-01.name}-to-${azurerm_virtual_network.vnet-main.name}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-01.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-main.id
}
resource "azurerm_virtual_network_peering" "MainToVnet02" {
  name = "Peer-${azurerm_virtual_network.vnet-main.name}-to-${azurerm_virtual_network.vnet-02.name}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-main.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-02.id
}
resource "azurerm_virtual_network_peering" "MainFromVnet02" {
  name = "Peer-${azurerm_virtual_network.vnet-02.name}-to-${azurerm_virtual_network.vnet-main.name}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet-02.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-main.id
}

#Create KeyVault ID
resource "random_id" "kvname" {
  byte_length = 5
  prefix = "keyvault"
}

#Keyvault Creation
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "kv1" {
  depends_on = [ azurerm_resource_group.rg ]
  name                        = random_id.kvname.hex
  location                    = var.region_name
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore",
    ]
    secret_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set",
    ]
    storage_permissions = [
      "Get",
    ]
  }
}

#Create KeyVault VM password
resource "random_password" "adminPW" {
  length  = 20
  special = true
}

#Create Key Vault Secret
resource "azurerm_key_vault_secret" "adminPW" {
  name         = "adminPW"
  value        = random_password.adminPW.result
  key_vault_id = azurerm_key_vault.kv1.id
  depends_on = [ azurerm_key_vault.kv1 ]
}

# Create Windows Virtual Machine Interface
resource "azurerm_network_interface" "tfVM01" {
  name                = "${var.tfVM01}-nic"
  location            = var.region_name
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "${azurerm_virtual_network.vnet-01.subnet.*.id[0]}"
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "tfVM01" {
  name                = "${var.tfVM01}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region_name
  size                = "Standard_F2"
  admin_username      = var.adminUN
  admin_password      = random_password.adminPW.result
  network_interface_ids = [
    azurerm_network_interface.tfVM01.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
