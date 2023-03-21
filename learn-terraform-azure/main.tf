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

resource "azurerm_resource_group" "rg-01" {
  name     = var.resource_group_name
  location = var.region_name
  tags = {
    Environment = "Terraform Getting Started"
    Team = "DevOps"
  }
}

# Create VNets
resource "azurerm_virtual_network" "vnet-01" {
  name                = var.vnet_name_1
  address_space       = ["10.0.2.0/23"]
  location            = var.region_name
  resource_group_name = azurerm_resource_group.rg-01.name

  subnet {
    name = var.subnet_name_1
    address_prefix = "10.0.2.0/24"
  }
}

resource "azurerm_virtual_network" "vnet-02" {
  name                = var.vnet_name_2
  address_space       = ["10.0.4.0/23"]
  location            = var.region_name
  resource_group_name = azurerm_resource_group.rg-01.name

  subnet {
    name = var.subnet_name_2
    address_prefix = "10.0.4.0/24"
  }
}

/* LEGACY - Peer Vnets
resource "azurerm_virtual_network_peering" "MainToVnet01" {
  name = "Peer-${azurerm_virtual_network.vnet-main.name}-to-${azurerm_virtual_network.vnet-01.name}"
  resource_group_name = azurerm_resource_group.rg-01.name
  virtual_network_name = azurerm_virtual_network.vnet-main.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-01.id
}
resource "azurerm_virtual_network_peering" "MainFromVnet01" {
  name = "Peer-${azurerm_virtual_network.vnet-01.name}-to-${azurerm_virtual_network.vnet-main.name}"
  resource_group_name = azurerm_resource_group.rg-01.name
  virtual_network_name = azurerm_virtual_network.vnet-01.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-main.id
}
resource "azurerm_virtual_network_peering" "MainToVnet02" {
  name = "Peer-${azurerm_virtual_network.vnet-main.name}-to-${azurerm_virtual_network.vnet-02.name}"
  resource_group_name = azurerm_resource_group.rg-01.name
  virtual_network_name = azurerm_virtual_network.vnet-main.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-02.id
}
resource "azurerm_virtual_network_peering" "MainFromVnet02" {
  name = "Peer-${azurerm_virtual_network.vnet-02.name}-to-${azurerm_virtual_network.vnet-main.name}"
  resource_group_name = azurerm_resource_group.rg-01.name
  virtual_network_name = azurerm_virtual_network.vnet-02.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-main.id
}
*/

# Create Virutal WAN
resource "azurerm_virtual_wan" "vWAN" {
  name = var.vwan_name
  location = var.region_name
  resource_group_name = azurerm_resource_group.rg-01.name
}

# Create Virutal Hub
resource "azurerm_virtual_hub" "vHUB" {
  name = var.vhub_name
  location = var.region_name
  resource_group_name = azurerm_resource_group.rg-01.name
  virtual_wan_id = azurerm_virtual_wan.vWAN.id
  address_prefix = "10.0.0.0/23"
}

# Create connections from Virutal Hub to VNets
resource "azurerm_virtual_hub_connection" "vHUB-connection-01" {
  name = var.vhub_connecion_name_01
  virtual_hub_id = azurerm_virtual_hub.vHUB.id
  remote_virtual_network_id = azurerm_virtual_network.vnet-01.id
}
resource "azurerm_virtual_hub_connection" "vHUB-connection-02" {
  name = var.vhub_connecion_name_02
  virtual_hub_id = azurerm_virtual_hub.vHUB.id
  remote_virtual_network_id = azurerm_virtual_network.vnet-02.id
}

# Create VPN Server Configuration
resource "azurerm_vpn_server_configuration" "vpn-server" {
  name = var.vpn_config_01
  resource_group_name = azurerm_resource_group.rg-01.name
  location = var.region_name
  vpn_authentication_types = ["AAD"]

  azure_active_directory_authentication {
    audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
    issuer = "https://sts.windows.net/${var.directory_id}/"
    tenant = "https://login.microsoftonline.com/${var.directory_id}/"
  }
}

# Create Point to Site VPN Gateway
resource "azurerm_point_to_site_vpn_gateway" "p2s-01" {
  name = var.p2s_name_01
  location = var.region_name
  resource_group_name = azurerm_resource_group.rg-01.name
  virtual_hub_id = azurerm_virtual_hub.vHUB.id
  vpn_server_configuration_id = azurerm_vpn_server_configuration.vpn-server.id
  scale_unit = 1

  connection_configuration {
    name = var.p2s_gateway_config_name_01

    vpn_client_address_pool {
      address_prefixes = [
        "192.168.0.0/24"
      ]
    }
  }
}

# Create Key Vault ID
resource "random_id" "kvname" {
  byte_length = 5
  prefix = "keyvault"
}

# Create Key Vault
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "kv1" {
  depends_on = [ azurerm_resource_group.rg-01 ]
  name                        = random_id.kvname.hex
  location                    = var.region_name
  resource_group_name         = azurerm_resource_group.rg-01.name
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

# Create Key Vault VM password
resource "random_password" "adminPW" {
  length  = 20
  special = true
}

# Create Key Vault Secret for VM password
resource "azurerm_key_vault_secret" "adminPW" {
  name         = "adminPW"
  value        = random_password.adminPW.result
  key_vault_id = azurerm_key_vault.kv1.id
  depends_on = [ azurerm_key_vault.kv1 ]
}

# Create Windows Virtual Machines
resource "azurerm_windows_virtual_machine" "vm-01" {
  name                = "${var.vm_name_1}"
  resource_group_name = azurerm_resource_group.rg-01.name
  location            = var.region_name
  size                = "Standard_F2"
  admin_username      = var.adminUN
  admin_password      = random_password.adminPW.result
  network_interface_ids = [
    azurerm_network_interface.vm-01.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}
resource "azurerm_windows_virtual_machine" "vm-02" {
  name                = "${var.vm_name_2}"
  resource_group_name = azurerm_resource_group.rg-01.name
  location            = var.region_name
  size                = "Standard_F2"
  admin_username      = var.adminUN
  admin_password      = azurerm_key_vault_secret.adminPW.value
  network_interface_ids = [
    azurerm_network_interface.vm-02.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# Create Windows Virtual Machine Interfaces
resource "azurerm_network_interface" "vm-01" {
  name                = "${var.vm_name_1}-nic"
  location            = var.region_name
  resource_group_name = azurerm_resource_group.rg-01.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "${azurerm_virtual_network.vnet-01.subnet.*.id[0]}"
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_interface" "vm-02" {
  name                = "${var.vm_name_2}-nic"
  location            = var.region_name
  resource_group_name = azurerm_resource_group.rg-01.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "${azurerm_virtual_network.vnet-02.subnet.*.id[0]}"
    private_ip_address_allocation = "Dynamic"
  }
}