variable "resource_group_name" {
  default = "tfTest"
}

variable "vnet_name_1" {
  default = "myTFVnet01"
}

variable "vnet_name_2" {
  default = "myTFVnet02"
}

variable "vnet_name_3" {
  default = "myTFVnet03"
}

variable "region_name" {
  default = "australiaeast"
}

variable "subnet_name_1" {
  default = "myTFVnet01Sub1"
}

variable "subnet_name_2" {
  default = "myTFVnet02Sub1"
}

variable "subnet_name_3" {
  default = "myTFVnet03Sub1"
}

variable "vm_name_1" {
  default = "tfVM01"
}

variable "vm_name_2" {
  default = "tfVM02"
}

variable "adminUN" {
  default = "adminuser"
}

variable "vhub_name" {
  default = "tf-vhub"
}

variable "vwan_name" {
  default = "tf-vwan"
}

variable "vpn_config_01" {
  default = "vpn-config"
}

variable "vhub_connecion_name_01" {
  default = "vhub-connection-01"
}

variable "vhub_connecion_name_02" {
  default = "vhub-connection-02"
}

variable "p2s_name_01" {
  default = "p2s-01"
}

variable "p2s_gateway_config_name_01" {
  default = "p2s-gateway-config-01"
}

variable "directory_id" {
  description = "Azure AD Tenant ID"
  default = "230685fb-eb1f-4dae-a440-12119ef36312"
}

variable "VPN-Users-GUID" {
  default = "2a0b3563-ba10-4948-be9a-975588ef86b3"
}