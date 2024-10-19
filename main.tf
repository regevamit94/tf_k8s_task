terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.1.0"
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

resource "azurerm_resource_group" "hometask_rg" {
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
        --scope "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.hometask_rg.name}"
    EOT
  }
  depends_on = [azurerm_resource_group.hometask_rg]
}


resource "azurerm_virtual_network" "hometask_virtual_network" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.region
  resource_group_name = azurerm_resource_group.hometask_rg.name

  tags = {
    Name = "hometask virtual network"
  }
}

resource "azurerm_subnet" "hometask_subnet" {
  name = var.subnet_name
  resource_group_name = azurerm_resource_group.hometask_rg.name
  virtual_network_name = azurerm_virtual_network.hometask_virtual_network.name
  address_prefixes = var.subnet_cidr

} 

resource "azurerm_public_ip" "hometask_load_balancer_ip" {
  name                = "hometask-load-balancer-ip"
  location            = var.region
  resource_group_name = azurerm_resource_group.hometask_rg.name
  allocation_method   = "Static"

  tags = {
    Name = "hometask load balancer public ip"
  }
}

resource "azurerm_container_registry" "images_vault" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.hometask_rg.name
  location            = azurerm_resource_group.hometask_rg.location
  sku                 = "Premium"
}

resource "azurerm_kubernetes_cluster" "hometask_AKS" {
  name                = var.aks_name
  resource_group_name = azurerm_resource_group.hometask_rg.name
  location            = azurerm_resource_group.hometask_rg.location
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

data "azurerm_container_registry" "my_acr" {
  name                = azurerm_container_registry.images_vault.name
  resource_group_name = azurerm_resource_group.hometask_rg.name
}

resource "azurerm_container_registry_scope_map" "acr_scope_map" {
  name                    = "acr-scope-map"
  resource_group_name     = azurerm_resource_group.hometask_rg.name
  container_registry_name  = azurerm_container_registry.images_vault.name

  actions = ["repositories/*/content/read"]
}


resource "azurerm_container_registry_token" "acr_token" {
  name                       = "acr-token"
  resource_group_name        = azurerm_resource_group.hometask_rg.name
  container_registry_name    = azurerm_container_registry.images_vault.name
  scope_map_id               = azurerm_container_registry_scope_map.acr_scope_map.id
  enabled                    = true
}

resource "azurerm_container_registry_token_password" "acr_token_password" {
  container_registry_token_id = azurerm_container_registry_token.acr_token.id

  password1 {
  }
}

output "acr_token_password" {
  value = azurerm_container_registry_token_password.acr_token_password.password1
  sensitive = true
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.hometask_AKS.kube_config[0].host
  client_certificate      = base64decode(azurerm_kubernetes_cluster.hometask_AKS.kube_config[0].client_certificate)
  client_key              = base64decode(azurerm_kubernetes_cluster.hometask_AKS.kube_config[0].client_key)
  cluster_ca_certificate  = base64decode(azurerm_kubernetes_cluster.hometask_AKS.kube_config[0].cluster_ca_certificate)
}

resource "kubernetes_secret" "acr_docker_registry_secret" {
  metadata {
    name      = "acr-docker-registry-secret"
    namespace = "default"
  }

  type = "kubernetes.io/dockerconfigjson"
  
  data = {
    ".dockerconfigjson" = jsonencode({
      "auths" = {
        "${azurerm_container_registry.images_vault.login_server}" = {
          "username" = azurerm_container_registry_token.acr_token.name
          "password" = azurerm_container_registry_token_password.acr_token_password.password1[0].value
          "auth"     = base64encode("${azurerm_container_registry_token.acr_token.name}:${azurerm_container_registry_token_password.acr_token_password.password1[0].value}")
        }
      }
    })
  }
}

/*
#Creation of json local file to check the error: "Secret "acr-docker-registry-secret" is invalid: data[.dockerconfigjson]: Invalid value: "<secret contents redacted>": invalid character 'e' looking for beginning of value"
resource "local_file" "docker_config_json" {
  content = jsonencode({
    "auths" = {
      "${azurerm_container_registry.images_vault.login_server}" = {
        "username" = azurerm_container_registry_token.acr_token.name
        "password" = azurerm_container_registry_token_password.acr_token_password.password1[0].value
        "auth"     = base64encode("${azurerm_container_registry_token.acr_token.name}:${azurerm_container_registry_token_password.acr_token_password.password1[0].value}")
      }
    }
  })
  filename = "${path.module}/docker_config.json"
}
*/


# Using that didn't work for some reason (ask for explanation)
resource "azurerm_role_assignment" "assign_acr_to_k8s" {
  principal_id                     = azurerm_kubernetes_cluster.hometask_AKS.identity[0].principal_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.images_vault.id
  skip_service_principal_aad_check = true

  depends_on = [null_resource.run_role_assignment_script]
}

# After Terraform finishes creating resources, manually point kubectl to the azure AKS:
# az aks get-credentials --resource-group ${var.my_resource_group_name} --name ${var.aks_name}



# Organization must be created in advance and cannot be created with terraform #
provider "azuredevops" {
  org_service_url       =  var.org_service_url
  personal_access_token =  var.org_pat
}

resource "azuredevops_project" "cicd_project" {
  name               = var.cicd_project_name
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
}

locals {
  my_variables = [
    {
      name      = "ACR_LOGIN_SERVER"
      value     = "${azurerm_container_registry.images_vault.name}.azurecr.io"
      is_secret = false
    },
    {
      name      = "ACR_NAME"
      value     = azurerm_container_registry.images_vault.name
      is_secret = false
    },
    {
      name      = "ACR_SERVICE_CON"
      value     = azuredevops_serviceendpoint_dockerregistry.acr_service_connection.service_endpoint_name
      is_secret = false
    },
    {
      name      = "RESOURCE_GRP"
      value     = azurerm_resource_group.hometask_rg.name
      is_secret = false
    },
    {
      name      = "AKS_CLUSTER"
      value     = azurerm_kubernetes_cluster.hometask_AKS.name
      is_secret = false
    },
    {
      name      = "IMAGE_NAME"
      value     = "hometask-image"
      is_secret = false
    },
    {
      name      = "IMAGE_TAG"
      value     = "$(Build.BuildId)"
      is_secret = false
    },
    {
      name      = "K8S_SERVICE_CON"
      value     = azuredevops_serviceendpoint_dockerregistry.acr_service_connection.service_endpoint_name
      is_secret = false
    }
  ]
}

resource "azuredevops_serviceendpoint_dockerregistry" "acr_service_connection" {
  project_id            = azuredevops_project.cicd_project.id
  service_endpoint_name = var.to_acr_service_connection_name
  description           = "Docker registry service connection for ACR"
  
  docker_registry       = azurerm_container_registry.images_vault.login_server
  docker_username       = var.client_id
  docker_password       = var.client_secret
}

resource "azuredevops_serviceendpoint_azurerm" "arm_service_connection" {
  project_id            = azuredevops_project.cicd_project.id
  service_endpoint_name = var.to_rg_service_connection_name
  description           = "Azure Resource Manager service connection for the resource group"

  azurerm_spn_tenantid      = var.tenant_id
  azurerm_subscription_id   = var.subscription_id
  azurerm_subscription_name = "my subscription name"
  environment               = "AzureCloud"
  resource_group = azurerm_resource_group.hometask_rg.name
}

resource "azuredevops_variable_group" "my_variable_group" {
  project_id  = azuredevops_project.cicd_project.id
  name        =  var.var_group_name
  description = "Variable group for CI/CD"

  dynamic "variable" {
    for_each = local.my_variables
    
    content {
      name      = variable.value.name
      value     = variable.value.value
    }
  }
}


