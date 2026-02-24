#Common variables
rg = "tf-rg-2003"
location = "uksouth"
vnet = "vnet-test-tf1"
jumpbox_subnet = "jumpbox-subnet"
private_endpoint_subnet = "private-endpoints"
vnet_spoke = "vnet-spoke-tf2"

db_password = "gvY1Sf3x5O82"

cmk_kv = "kv-tf-cmk-123"
cmk_kv_key = "cmk-key-tf"
uai_id_cmk = "uai-cmk-tf"

storage_account = "sttfcmk123"
acr_name = "acrtfcmk123"

pe_kv = "pe-kv-tf"
pe_acr = "pe-acr-tf"
pe_stg_blob = "pe-stg-blob-tf"
pe_stg_file = "pe-stg-file-tf"


#AKS related variables
aks_subnet = "aks-subnet"
cluster_identity_uai = "aks-cluster-identity-uai"
rg_aks_nodes = "aks-nodes-rg-tf-test"
user_pool = "workload01"
aks_name = "aks-tf-test-cmk"
des_name = "des-aks-tf-test"


route_table_name = "rt-spoke-tf-test"


# project = "seerp1"
# environment = "test"
