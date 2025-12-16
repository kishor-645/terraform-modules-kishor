variable rg {
  type        = string
  default     = ""
  description = "description"
}

variable environment {
  type        = string
  default     = ""
  description = "description"
}

variable location {
  type        = string
  default     = ""
  description = "description"
}

variable private_endpoint_subnet {
  type        = string
  default     = ""
  description = "Private endpoint subnet name"
}

variable jumpbox_subnet {
  type        = string
  default     = ""
  description = "Jumpbox subnet name"
}

variable vnet {
  type        = string
  default     = ""
  description = "Virtual network name"
}

variable storage_account {
  type        = string
  default     = ""
  description = "description"
}




variable rg_aks_nodes {
  type        = string
  default     = ""
  description = "description"
}

variable uai_id_cmk {
  type        = string
  default     = ""
  description = "description"
}

variable cmk_kv {
  type        = string
  default     = ""
  description = "description"
}

variable des_name {
  type        = string
  default     = ""
  description = "description"
}

variable cmk_kv_key {
  type        = string
  default     = ""
  description = "description"
}

variable aks_name {
  type        = string
  default     = ""
  description = "description"
}

variable aks_subnet {
  type        = string
  default     = ""
  description = "AKS subnet name"
}

variable cluster_identity_uai {
  type        = string
  default     = ""
  description = "description"
}

variable user_pool {
  type        = string
  default     = ""
  description = "description"
}

variable acr_name {
  type        = string
  default     = ""
  description = "Azure Container Registry name"
}

variable pe_kv {
  type        = string
  default     = ""
  description = "Private endpoint name for Key Vault"
}

variable pe_acr {
  type        = string
  default     = ""
  description = "Private endpoint name for ACR"
}

variable pe_stg_blob {
  type        = string
  default     = ""
  description = "Private endpoint name for Storage Blob"
}

variable pe_stg_file {
  type        = string
  default     = ""
  description = "Private endpoint name for Storage File"
}