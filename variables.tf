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

variable org_pat {
  type        = string
  description = "My azure devops personal access token"
}

########### End of privileged data #############

variable "region" {
  type        = string
  default     = "northeurope"
  description = "The region I use"
}

variable "my_resource_group_name" {
  type        = string
  default     = "hometask_rg"
  description = "My resource group name"
}

variable acr_name {
  type        = string
  default     = "hometaskregistry"
  description = "description"
}


variable "vnet_name" {
  type        = string
  default     = "hometask_vnet"
  description = "My virtual network name"
}

variable "address_space" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "My subnet"
}

variable "subnet_name" {
  type        = string
  default     = "hometask_subnet"
  description = "My subnet name"
}

variable "subnet_cidr" {
  type        = list(string)
  default     = ["10.0.0.0/24"]
  description = "My subnet cidr"
}

variable aks_name {
  type        = string
  default     = "hometask_AKS_Cluster"
  description = "description"
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

variable org_service_url {
  type        = string
  default     = "https://dev.azure.com/regevamit"
}

variable cicd_project_name {
  type        = string
  default     = "hometask-CI_CD"
}

variable var_group_name {
  type        = string
  default     = "hometask_VAR"
}


variable to_acr_service_connection_name {
  type        = string
  default     = "project_access_to_acr"
  description = "description"
}

variable to_rg_service_connection_name {
  type        = string
  default     = "access_to_azure_resources"
  description = "description"
}
