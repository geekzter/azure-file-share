variable location {
  default                      = "westeurope"
}

variable organization {
  default                      = "geekzter"
}

variable resource_group {
  default                      = "filebackup"
}

variable root_cert_pem_file {
  default                      = "../certificates/root_cert.pem"
}
variable root_cert_cer_file {
  default                      = "../certificates/root_cert.cer"
}
variable root_cert_der_file {
  default                      = "../certificates/root_cert.der"
}
variable root_cert_private_pem_file {
  default                      = "../certificates/root_cert_private.pem"
}
variable root_cert_public_pem_file {
  default                      = "../certificates/root_cert_public.pem"
}
variable client_cert_pem_file {
  default                      = "../certificates/client_cert.pem"
}
variable client_cert_p12_file {
  default                      = "../certificates/client_cert.p12"
}
variable client_cert_public_pem_file {
  default                      = "../certificates/client_cert_public.pem"
}
variable client_cert_private_pem_file {
  default                      = "../certificates/client_cert_private.pem"
}

variable storage_subnet {
  default                      = "default"
}

variable tags {
  description                  = "A map of the tags to use for the resources that are deployed"
  type                         = map

  default = {
    application                = "File Backup"
    provisioner                = "terraform"
    shutdown                   = "true"
  }
} 

variable vdc_config {
  type                         = map

  default = {
    vnet_range                 = "10.0.0.0/16"
    vnet_mgmt_subnet           = "10.0.2.128/26"
    vnet_vpn_subnet            = "10.0.3.224/27"
    vnet_paas_subnet           = "10.0.4.0/26"

    vpn_range                  = "192.168.0.0/24"
  }
}

variable virtual_network {
  default                      = "Backup-vnet"
}