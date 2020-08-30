locals {
  vm_name                      = "${data.azurerm_resource_group.vm_resource_group.name}-${var.name}"
  vm_computer_name             = substr(lower(replace(local.vm_name,"-","")),0,15)
}

data azurerm_client_config current {}

data azurerm_resource_group vm_resource_group {
  name                         = var.resource_group_name
}

resource azurerm_public_ip pip {
  name                         = "${local.vm_name}-pip"
  location                     = data.azurerm_resource_group.vm_resource_group.location
  resource_group_name          = data.azurerm_resource_group.vm_resource_group.name
  allocation_method            = "Static"
  sku                          = "Standard"

  tags                         = var.tags
}

resource azurerm_network_interface nic {
  name                         = "${local.vm_name}-nic"
  location                     = data.azurerm_resource_group.vm_resource_group.location
  resource_group_name          = data.azurerm_resource_group.vm_resource_group.name

  ip_configuration {
    name                       = "ipconfig"
    subnet_id                  = var.vm_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id       = azurerm_public_ip.pip.id
  }

  tags                         = var.tags
}

resource azurerm_network_security_group nsg {
  name                         = "${data.azurerm_resource_group.vm_resource_group.name}-linux-nsg"
  location                     = data.azurerm_resource_group.vm_resource_group.location
  resource_group_name          = data.azurerm_resource_group.vm_resource_group.name

  security_rule {
    name                       = "InboundSSH"
    priority                   = 202
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags                         = var.tags
}

resource azurerm_network_interface_security_group_association nic_nsg {
  network_interface_id         = azurerm_network_interface.nic.id
  network_security_group_id    = azurerm_network_security_group.nsg.id
}

resource azurerm_linux_virtual_machine vm {
  name                         = local.vm_name
  location                     = data.azurerm_resource_group.vm_resource_group.location
  resource_group_name          = data.azurerm_resource_group.vm_resource_group.name
  size                         = var.vm_size
  admin_username               = var.user_name
  admin_password               = var.user_password
  disable_password_authentication = false
  network_interface_ids        = [azurerm_network_interface.nic.id]
  computer_name                = local.vm_computer_name

  admin_ssh_key {
    username                   = var.user_name
    public_key                 = file(var.ssh_public_key)
  }

  os_disk {
    caching                    = "ReadWrite"
    storage_account_type       = "Premium_LRS"
  }

  source_image_reference {
    publisher                  = var.os_publisher
    offer                      = var.os_offer
    sku                        = var.os_sku
    version                    = var.os_version
  }

  tags                         = var.tags
  depends_on                   = [azurerm_network_interface_security_group_association.nic_nsg]
}

resource null_resource start_vm {
  # Always run this
  triggers                     = {
    always_run                 = timestamp()
  }

  provisioner local-exec {
    # Start VM, so we can execute script through SSH
    command                    = "az vm start --ids ${azurerm_linux_virtual_machine.vm.id}"
  }
}

/*
resource azurerm_virtual_machine_extension vm_monitor {
  name                         = "MMAExtension"
  virtual_machine_id           = azurerm_linux_virtual_machine.vm.id
  publisher                    = "Microsoft.Azure.Monitor"
  type                         = "AzureMonitorLinuxAgent"
  type_handler_version         = "0.9"
  auto_upgrade_minor_version   = true
  settings                     = <<EOF
    {
      "workspaceId"            : "${data.azurerm_log_analytics_workspace.monitor.workspace_id}",
      "azureResourceId"        : "${azurerm_linux_virtual_machine.vm.id}",
      "stopOnMultipleConnections": "true"
    }
  EOF
  protected_settings = <<EOF
    { 
      "workspaceKey"           : "${data.azurerm_log_analytics_workspace.monitor.primary_shared_key}"
    } 
  EOF
  count                        = var.log_analytics_workspace_id != null ? 1 : 0
  tags                         = var.tags
  depends_on                   = [null_resource.start_vm]
}
*/

/*
resource azurerm_virtual_machine_extension vm_diagnostics {
  name                         = "Microsoft.Insights.VMDiagnosticsSettings"
  virtual_machine_id           = azurerm_linux_virtual_machine.vm.id
  publisher                    = "Microsoft.Azure.Diagnostics"
  type                         = "IaaSDiagnostics"
  type_handler_version         = "1.17"
  auto_upgrade_minor_version   = true
  settings                     = templatefile("${path.module}/scripts/host/vmdiagnostics.json", { 
    storage_account_name       = data.azurerm_storage_account.diagnostics.name, 
    virtual_machine_id         = azurerm_linux_virtual_machine.vm.id, 
  # application_insights_key   = azurerm_application_insights.app_insights.instrumentation_key
  })
  protected_settings = <<EOF
    { 
      "storageAccountName"     : "${data.azurerm_storage_account.diagnostics.name}",
      "storageAccountKey"      : "${data.azurerm_storage_account.diagnostics.primary_access_key}",
      "storageAccountEndPoint" : "https://core.windows.net"
    } 
  EOF
  count                        = var.diagnostics ? 1 : 0
  tags                         = var.tags
  depends_on                   = [
                                  null_resource.start_vm
                                 ]
}
*/
