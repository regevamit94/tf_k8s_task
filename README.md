# Azure Resource Group Deployment with Terraform and CI/CD Pipeline

This project automates the creation of an Azure resource group and the deployment of an app through a CI/CD pipeline using Terraform and Azure DevOps.

## Prerequisites

Before deploying this project, you need to manually create the organization in your Azure tenant. **Note:** Azure organizations can only be created manually.

### Azure Tenant Details Required:

Make sure to provide the following Azure tenant details before running the Terraform scripts:
- `subscription_id` – Azure Subscription ID
- `client_id` – Azure Client ID (from your Azure Active Directory)
- `client_secret` – Azure Client Secret
- `tenant_id` – Azure Tenant ID
- `org_pat` – Azure DevOps Organization Personal Access Token (PAT)

It is recommended to store these sensitive details in `terraform.tfvars` instead of hardcoding them directly in the scripts.

## Project Structure

- **main.tf**: The main Terraform file that provisions the Azure resources.
- **variables.tf**: File for defining the variables used in the Terraform deployment.
- **azure-pipeline.yaml**: CI/CD pipeline configuration file for Azure DevOps. This pipeline builds the app image (CI) and deploys it to the Kubernetes cluster (CD).
- **Dockerfile**: Defines the steps to build the application container image.
- **app.yaml**: Kubernetes Deployment, Service, and ConfigMap definitions for deploying the app to the cluster.

## Terraform Features

- Creates an Azure DevOps project in the provided organization.
- Establishes service connections for deploying resources.
- Creates a variable group within the Azure DevOps project for storing sensitive values (e.g., credentials).