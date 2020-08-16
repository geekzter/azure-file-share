output cert_password {
  sensitive   = true
  value       = module.vpn.cert_password
}

output client_cert {
  value       = module.vpn.client_cert
}

output client_key {
  value       = module.vpn.client_key
}

output root_cert_cer {
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

output virtual_network_id {
  value       = module.vnet.virtual_network_id
}