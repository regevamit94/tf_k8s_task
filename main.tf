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

data "azurerm_client_config" "current_client" {}

resource "null_resource" "run_role_assignment_script" {
  provisioner "local-exec" {
    command = <<EOT
      #!/bin/bash

      principal_id="${data.azurerm_client_config.current_client.object_id}"

      if [[ -z "$principal_id" ]]; then
        echo "Error: Unable to get the principal ID from Terraform."
        exit 1
      fi

      echo "Terraform is using the principal with Object ID: $principal_id"

      az role assignment create \
        --assignee $principal_id \
        --role "User Access Administrator" \
        --scope "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.hometask_RG.name}"
    EOT
  }
  depends_on = [azurerm_resource_group.hometask_RG]
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

resource "azurerm_container_registry" "images_vault" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.hometask_RG.name
  location            = azurerm_resource_group.hometask_RG.location
  sku                 = "Premium"
}

resource "azurerm_kubernetes_cluster" "hometask_AKS" {
name                = var.aks_name
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


resource "azurerm_role_assignment" "assign_acr_to_k8s" {
  principal_id                     = azurerm_kubernetes_cluster.hometask_AKS.identity[0].principal_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.images_vault.id
  skip_service_principal_aad_check = true

}

resource "azuread_application" "my_application" {
  display_name = "My Application"
}

resource "azuread_service_principal" "my_service_principal" {
  application_id = azuread_application.my_application.application_id
}

resource "azurerm_role_assignment" "my_push_to_acr_role" {
    principal_id         = azuread_service_principal.my_service_principal.id
    role_definition_name  = "AcrPush"
    scope                = azurerm_container_registry.images_vault.id
}
/*
After Terraform finishes creating resources, manually point kubectl to the azure AKS:
az aks get-credentials --resource-group ${var.my_resource_group_name} --name ${var.aks_name}
*/

