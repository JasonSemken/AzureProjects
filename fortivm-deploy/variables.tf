variable "resource_group_name_01" {
description = "Name of the primary resource group"
  default = "tfFortiVM"
}

variable "region_name" {
  default = "australiaeast"
}

variable "vnet_01" {
  default = "FortiVM"
}

variable "vnet_01_address_space" {
  default = ["10.0.0.0/22"]
}

variable "subnet_name_01" {
  default = "External"
}

variable "subnet_01_address_prefix" {
  default = "10.0.0.0/24"
}

variable "subnet_name_02" {
  default = "Internal"
}

variable "subnet_02_address_prefix" {
  default = "10.0.1.0/24"
}