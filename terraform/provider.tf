provider azurerm {
    version = "~> 2.22"
    features {
        virtual_machine {
            delete_os_disk_on_deletion = true
        }
    }
    subscription_id = "fd1f5ca3-b0fc-491f-a932-f11fd6f7f923"
}

provider null {
    version = "~> 2.1"
}

provider random {
    version = "~> 2.3"
}

provider tls {
    version = "~> 2.2"
}