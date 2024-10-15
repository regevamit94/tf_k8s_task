# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}


provider "azurerm" {
  features {}

    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    tenant_id = var.tenant_id

    #resource_provider_registrations = "none"
}


resource "azurerm_resource_group" "hometask_RG" {
  name     = var.my_resource_group_name
  location = var.region

  tags = {
    Name = "hometask resource group"
  }

}

resource "azurerm_virtual_network" "hometask_virtual_network" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.region
  resource_group_name = azurerm_resource_group.hometask_RG.name

  tags = {
    Name = "hometask virtual network"
  }
}

resource "azurerm_subnet" "hometask_subnet" {
  name = var.subnet_name
  resource_group_name = azurerm_resource_group.hometask_RG.name
  virtual_network_name = azurerm_virtual_network.hometask_virtual_network.name
  address_prefixes = var.subnet_cidr

} 

resource "azurerm_public_ip" "hometask_load_balancer_ip" {
  name                = "hometask-load-balancer-ip"
  location            = var.region
  resource_group_name = azurerm_resource_group.hometask_RG.name
  allocation_method   = "Static"

  tags = {
    Name = "hometask load balancer public ip"
  }
}


resource "azurerm_kubernetes_cluster" "hometask_AKS" {
name                = "hometask_AKS_Cluster"
resource_group_name = azurerm_resource_group.hometask_RG.name
location            = azurerm_resource_group.hometask_RG.location
dns_prefix          = "hometaskK8S"

default_node_pool {
    name       = "agentpool"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.hometask_subnet.id
    }

identity {
    type = "SystemAssigned"
    }

network_profile {
    network_plugin    = "azure"
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
    }

    tags = {
        Name = "hometask Azure K8S Cluster"
    }
  depends_on = [azurerm_subnet.hometask_subnet]
}

