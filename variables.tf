########### Start of privileged data #############
variable "subscription_id" {
  type        = string
  description = "My Azure account subscription ID"   
}

variable "client_id" {
  type        = string
  description = "My Azure account client ID"
}

variable "client_secret" {
  type        = string
  description = "My Azure account client cecret"
  sensitive = true
}

variable "tenant_id" {
  type        = string
  description = "My Azure account tenant ID"
}
########### End of privileged data #############

variable "region" {
  type        = string
  default     = "northeurope"
  description = "The region I use"
}

variable "my_resource_group_name" {
  type        = string
  default     = "hometask_RG"
  description = "My resource group name"
}

variable "vnet_name" {
  type        = string
  default     = "hometask_VNet"
  description = "My virtual network name"
}

variable "address_space" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "My subnet"
}

variable "subnet_name" {
  type        = string
  default     = "hometask_Subnet"
  description = "My subnet name"
}

variable "subnet_cidr" {
  type        = list(string)
  default     = ["10.0.0.0/24"]
  description = "My subnet cidr"
}

#########     network_profile    #############
variable dns_service_ip {
  type        = string
  default     = "10.1.0.2"
  description = "description"
}

variable service_cidr {
  type        = string
  default     = "10.1.0.0/24"
  description = "description"
}


#############################################

