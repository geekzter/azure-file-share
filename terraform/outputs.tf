output cert_password {
  sensitive   = true
  value       = module.vpn.cert_password
}

output client_cert {
  sensitive   = true
  value       = module.vpn.client_cert
}

output client_key {
  sensitive   = true
  value       = module.vpn.client_key
}

output root_cert_cer {
  sensitive   = true
  value       = module.vpn.root_cert_cer
}

output gateway_id {
  value       = module.vpn.gateway_id
}

output gateway_fqdn {
  value       = module.vpn.gateway_fqdn
}

output gateway_ip {
  value       = module.vpn.gateway_ip
}

output storage_blob_fqdn {
  value       = azurerm_storage_account.file_storage.primary_blob_host
}

output storage_blob_ip_address {
  value       = azurerm_private_endpoint.storage_endpoint.private_dns_zone_configs.0.record_sets.0.ip_addresses[0]
}

output storage_file_fqdn {
  value       = azurerm_storage_account.file_storage.primary_file_host
}

output storage_file_ip_address {
  value       = azurerm_private_endpoint.file_share_endpoint.private_dns_zone_configs.0.record_sets.0.ip_addresses[0]
}

output virtual_network_id {
  value       = module.vnet.virtual_network_id
}