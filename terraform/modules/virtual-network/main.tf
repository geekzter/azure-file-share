data azurerm_resource_group rg {
  name                         = var.resource_group 
}

resource azurerm_network_security_group data_nsg {
  name                         = "${data.azurerm_resource_group.rg.name}-nsg"
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowAllTCPfromVPN"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.allow_range
    destination_address_prefix = "VirtualNetwork"
  }

  tags                         = var.tags
}

resource azurerm_virtual_network vnet {
  name                         = var.virtual_network
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  address_space                = [var.address_space]

  tags                         = var.tags
}

resource azurerm_subnet subnet {
  name                         = element(keys(var.subnets),count.index)
  virtual_network_name         = azurerm_virtual_network.vnet.name
  resource_group_name          = data.azurerm_resource_group.rg.name
  address_prefixes             = [element(values(var.subnets),count.index)]
  enforce_private_link_endpoint_network_policies = true
  count                        = length(var.subnets)
}

resource azurerm_private_dns_zone_virtual_network_link dns_link {
  name                         = "${azurerm_virtual_network.vnet.name}-zone-link${count.index+1}"
  resource_group_name          = data.azurerm_resource_group.rg.name
  private_dns_zone_name        = element(var.private_dns_zones,count.index)
  virtual_network_id           = azurerm_virtual_network.vnet.id

  count                        = length(var.private_dns_zones)
}