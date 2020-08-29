data azurerm_client_config current {}
data azurerm_subscription primary {}

# Random resource suffix, this will prevent name collisions when creating resources in parallel
resource random_string suffix {
  length                       = 4
  upper                        = false
  lower                        = true
  number                       = false
  special                      = false
}

# These variables will be used throughout the Terraform templates
locals {
  tags                         = merge(
    var.tags,
  )

  suffix                       = random_string.suffix.result

  lifecycle                    = {
    ignore_changes             = ["tags"]
  }
}

# Create Azure resource group to be used for VDC resources
resource azurerm_resource_group rg {
  name                         = var.resource_group
  location                     = var.location
  tags                         = local.tags
}

resource azurerm_storage_account file_storage {
  name                         = "${lower(azurerm_resource_group.rg.name)}storage${local.suffix}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  account_kind                 = "StorageV2"
  account_tier                 = "Standard"
  account_replication_type     = "LRS"
  allow_blob_public_access     = false

  tags                         = local.tags
}

resource azurerm_storage_account_network_rules file_storage_rules {
  resource_group_name          = azurerm_resource_group.rg.name
  storage_account_name         = azurerm_storage_account.file_storage.name
  default_action               = "Allow"
}

resource azurerm_storage_container backup_container {
  name                         = "backup"
  storage_account_name         = azurerm_storage_account.file_storage.name
  container_access_type        = "private"

  depends_on                   = [azurerm_storage_account_network_rules.file_storage_rules]
}

resource azurerm_storage_share file_share {
  name                         = "share"
  storage_account_name         = azurerm_storage_account.file_storage.name
  quota                        = 4096

  depends_on                   = [azurerm_storage_account_network_rules.file_storage_rules]
}

resource azurerm_private_dns_zone zone {
  for_each                     = {
    blob                       = "privatelink.blob.core.windows.net"
    file                       = "privatelink.file.core.windows.net"
  }
  name                         = each.value
  resource_group_name          = azurerm_resource_group.rg.name

  tags                         = var.tags
}

resource azurerm_private_endpoint storage_endpoint {
  name                         = "${azurerm_storage_account.file_storage.name}-blob-endpoint"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  
  subnet_id                    = module.vnet.subnet_ids["paas"]

  private_dns_zone_group {
    name                       = azurerm_private_dns_zone.zone["blob"].name
    private_dns_zone_ids       = [azurerm_private_dns_zone.zone["blob"].id]
  }

  private_service_connection {
    is_manual_connection       = false
    name                       = "${azurerm_storage_account.file_storage.name}-blob-endpoint-connection"
    private_connection_resource_id = azurerm_storage_account.file_storage.id
    subresource_names          = ["blob"]
  }

  tags                         = local.tags
}

resource azurerm_private_endpoint file_share_endpoint {
  name                         = "${azurerm_storage_account.file_storage.name}-file-endpoint"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  
  subnet_id                    = module.vnet.subnet_ids["paas"]

  private_dns_zone_group {
    name                       = azurerm_private_dns_zone.zone["file"].name
    private_dns_zone_ids       = [azurerm_private_dns_zone.zone["file"].id]
  }

  private_service_connection {
    is_manual_connection       = false
    name                       = "${azurerm_storage_account.file_storage.name}-file-endpoint-connection"
    private_connection_resource_id = azurerm_storage_account.file_storage.id
    subresource_names          = ["file"]
  }

  tags                         = local.tags
}

module vnet {
  source                       = "./modules/virtual-network"
  resource_group               = azurerm_resource_group.rg.name
  tags                         = local.tags

  address_space                = var.vdc_config["vnet_range"]
  allow_range                  = var.vdc_config["vpn_range"]
  private_dns_zones            = [for z in azurerm_private_dns_zone.zone : z.name]
  virtual_network              = "${azurerm_resource_group.rg.name}-network"
  subnets                      = {
    paas                       = var.vdc_config["vnet_paas_subnet"]
  }
}

module vpn {
  source                       = "./modules/p2s-vpn"
  resource_group_id            = azurerm_resource_group.rg.id
  location                     = azurerm_resource_group.rg.location
  tags                         = local.tags

  root_cert_cer_file           = var.root_cert_cer_file
  root_cert_der_file           = var.root_cert_der_file
  root_cert_pem_file           = var.root_cert_pem_file
  root_cert_private_pem_file   = var.root_cert_private_pem_file
  root_cert_public_pem_file    = var.root_cert_public_pem_file
  client_cert_pem_file         = var.client_cert_pem_file
  client_cert_p12_file         = var.client_cert_p12_file
  client_cert_public_pem_file  = var.client_cert_public_pem_file
  client_cert_private_pem_file = var.client_cert_private_pem_file

  organization                 = var.organization
  virtual_network_id           = module.vnet.virtual_network_id
  subnet_range                 = var.vdc_config["vnet_vpn_subnet"]
  vpn_range                    = var.vdc_config["vpn_range"]
}