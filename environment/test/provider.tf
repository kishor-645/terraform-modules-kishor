terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  subscription_id = "45e252f2-d253-4baa-9afd-57a4fbac93f4"
  
  features {
    resource_group {
      # Terraform won't delete a non-empty RG by default unless this is set to false
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      # Critical for Terraform to manage Keys without getting deleted on error
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}