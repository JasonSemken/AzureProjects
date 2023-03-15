variable "resource_group_name" {
  default = "tfTestie"
}

variable "vnet_name" {
  main = "myTFVnetMain"
  vnet01 = "myTFVnet01"
  vnet02 = "myTFVnet02"
}

variable "region" {
  default = "australiaeast"
}