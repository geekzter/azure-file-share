variable dependency_monitor {
    type                       = bool
    default                    = false
}
variable diagnostics {
    type                       = bool
    default                    = false
}
variable disk_encryption {
    type                       = bool
    default                    = false
}
variable name {}
variable os_offer {
  default                      = "UbuntuServer"
}
variable os_publisher {
  default                      = "Canonical"
}
variable os_sku {
  default                      = "18.04-LTS"
}
variable os_version {
    default                    = "latest"
}
variable resource_group_name {}
variable ssh_public_key {}
variable tags {}
variable user_name {}
variable user_password {}
variable vm_size {}
variable vm_subnet_id {}