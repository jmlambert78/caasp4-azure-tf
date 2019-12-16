# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "caasp4tf-eu-rg" {
    name     = var.caasp4_rg_name
    location = var.azure-region
    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "caasp4tf-network" {
    name                = "caasp4tf-vnet"
    address_space       = ["10.0.0.0/16"]
    location            =  var.azure-region
    resource_group_name = azurerm_resource_group.caasp4tf-eu-rg.name
    tags = {
        environment = "Terraform Demo"
    }
}
# to declare the private dns to the vnet
resource "azurerm_private_dns_zone_virtual_network_link" "privatejmllab" {
  name                  = "private-jmllab-dns-link"
  resource_group_name   = azurerm_private_dns_zone.jmllabsuse-private.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.jmllabsuse-private.name
  virtual_network_id    = azurerm_virtual_network.caasp4tf-network.id
}


# Create subnet
resource "azurerm_subnet" "caasp4tf-subnet" {
    name                 = "caasp4tf-subnet"
    resource_group_name  = azurerm_resource_group.caasp4tf-eu-rg.name
    virtual_network_name = azurerm_virtual_network.caasp4tf-network.name
    address_prefix       = "10.0.1.0/24"
}
variable "list-nodes" {
  default = ["admin","master1","node1","node2"]
}

# Create public IPs
resource "azurerm_public_ip" "caasp4tf-publicip" {
    name                         = "${var.list-nodes[count.index]}-PublicIP"
    location                     =  var.azure-region
    resource_group_name          = azurerm_resource_group.caasp4tf-eu-rg.name
    allocation_method            = "Static"
    tags = {
        environment = "Terraform Demo"
    }
	count                        = length(var.list-nodes)
}

output "public_ip_address-admin" {
  value = azurerm_public_ip.caasp4tf-publicip.*.ip_address
}
resource "azurerm_dns_a_record" "caasp4nodes" {
  name                = "caasp4-${var.list-nodes[count.index]}.${var.caasp4_dns_prefix}"
  zone_name           = azurerm_dns_zone.jmllabsuse.name
  resource_group_name = azurerm_dns_zone.jmllabsuse.resource_group_name
  ttl                 = 300
  records             = ["${azurerm_public_ip.caasp4tf-publicip[count.index].ip_address}"]
  count               = length(var.list-nodes)
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "caasp4tf-nsg" {
    name                = "caasp4tf-NetworkSecurityGroup"
    location            =  var.azure-region
    resource_group_name = azurerm_resource_group.caasp4tf-eu-rg.name
    tags = {
        environment = "Terraform Demo"
    }
}
variable "list-nsg-ports" {
   default = ["22","80","443","6443","7443","8443","4240","8472","10250","10256","30000-32767","2379-2380","2397","2793","2222"]

}
resource "azurerm_network_security_rule" "caasp4-nsg-rules" {
  name                        = "caasp4-${var.list-nsg-ports[count.index]}"
  priority                    = 1001+count.index
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = var.list-nsg-ports[count.index]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.caasp4tf-eu-rg.name
  network_security_group_name = azurerm_network_security_group.caasp4tf-nsg.name
  count                       =length(var.list-nsg-ports)
}
# Create network interfaces
resource "azurerm_network_interface" "caasp4tf-nics" {
    name                      = "caasp4tf-${var.list-nodes[count.index]}-nic"
    location                  = var.azure-region
    resource_group_name       = azurerm_resource_group.caasp4tf-eu-rg.name
    network_security_group_id = azurerm_network_security_group.caasp4tf-nsg.id

    ip_configuration {
        name                          = "caasp4tf-NicConfiguration-${var.list-nodes[count.index]}"
        subnet_id                     = azurerm_subnet.caasp4tf-subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.caasp4tf-publicip[count.index].id
    }
    count                     = length(var.list-nodes)
    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_private_dns_a_record" "caasp4nodesprivate" {
  name                = "caasp4-${var.list-nodes[count.index]}.${var.caasp4_dns_prefix}"
  zone_name           = azurerm_private_dns_zone.jmllabsuse-private.name
  resource_group_name = azurerm_private_dns_zone.jmllabsuse-private.resource_group_name
  ttl                 = 300
  records             = ["${azurerm_network_interface.caasp4tf-nics[count.index].ip_configuration[0].private_ip_address}"]
  count               = length(var.list-nodes)
}
# add *.cf for internal dns to master IP.
resource "azurerm_private_dns_a_record" "caasp4cfprivate" {
  name                = "*.cf"
  zone_name           = azurerm_private_dns_zone.jmllabsuse-private.name
  resource_group_name = azurerm_private_dns_zone.jmllabsuse-private.resource_group_name
  ttl                 = 300
  records             = ["${azurerm_network_interface.caasp4tf-nics[1].ip_configuration[0].private_ip_address}"]
}


# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.caasp4tf-eu-rg.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "caasp4tf-storageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.caasp4tf-eu-rg.name
    location                    =  var.azure-region
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}
# Create virtual machines
resource "azurerm_virtual_machine" "caasp4tf-VMs" {
    name                  = "caasp4tf-${var.list-nodes[count.index]}-VM"
    location              =  var.azure-region
    resource_group_name   = azurerm_resource_group.caasp4tf-eu-rg.name
    network_interface_ids = [azurerm_network_interface.caasp4tf-nics[count.index].id]
    vm_size               = "Standard_D4s_v3"

    storage_os_disk {
        name              = "caasp4tf-${var.list-nodes[count.index]}-OsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }
    delete_os_disk_on_termination = true
    delete_data_disks_on_termination = true

    storage_image_reference {
        publisher = "SUSE"
        offer     = "sles-15-sp1-byos"
        sku       = "gen1"
        version   = "latest"
    }

    os_profile {
        computer_name  = "caasp4tf-${var.list-nodes[count.index]}-vm"
        admin_username = "jmlambert"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/jmlambert/.ssh/authorized_keys"
            key_data = file(var.ssh_public_keys)
        }
    }

    boot_diagnostics {
        enabled = "false"
        storage_uri = azurerm_storage_account.caasp4tf-storageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
          provisioner "file" {

    source      = "reg-suse-jml-script.sh"
    destination = "/tmp/script.sh"
connection {
    type     = "ssh"
    user     = "jmlambert"
    host     =  azurerm_public_ip.caasp4tf-publicip[count.index].ip_address
    private_key = file(var.ssh_private_key_jml)
  }
  }
    provisioner "file" {

    source      = "bootstrap-caasp4.sh"
    destination = "/tmp/bootstrap-caasp4.sh"
    connection {
      type     = "ssh"
      user     = "jmlambert"
      host     =  azurerm_public_ip.caasp4tf-publicip[count.index].ip_address
      private_key = file(var.ssh_private_key_jml)
      }
    }
    provisioner "file" {

    source      = "swap.sh"
    destination = "/tmp/swap.sh"
    connection {
      type     = "ssh"
      user     = "jmlambert"
      host     =  azurerm_public_ip.caasp4tf-publicip[count.index].ip_address
      private_key = file(var.ssh_private_key_jml)
      }
    }
    provisioner "file" {

    source      = "nfsserver.sh"
    destination = "/tmp/nfsserver.sh"
    connection {
      type     = "ssh"
      user     = "jmlambert"
      host     =  azurerm_public_ip.caasp4tf-publicip[count.index].ip_address
      private_key = file(var.ssh_private_key_jml)
      }
    }


    provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",      "/tmp/script.sh args",
      "chmod +x /tmp/swap.sh",        "/tmp/swap.sh",
    ]
    connection {
       type     = "ssh"
       user     = "jmlambert"
       host     = azurerm_public_ip.caasp4tf-publicip[count.index].ip_address
       private_key = file(var.ssh_private_key_jml)

       }
    }
    count = 4 
}
## To be done only on NODE VMs add a 100Gb for containers
resource "azurerm_managed_disk" "caasp4-datadisks" {
  name                 = "caasp4tf-${var.list-nodes[count.index+2]}-datadisk1"
  location              =  var.azure-region
  resource_group_name   = azurerm_resource_group.caasp4tf-eu-rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 100
  count = 2
}

resource "azurerm_virtual_machine_data_disk_attachment" "caasp4-datadisks" {
  managed_disk_id    = azurerm_managed_disk.caasp4-datadisks[count.index].id
  virtual_machine_id = azurerm_virtual_machine.caasp4tf-VMs[count.index+2].id
  lun                = "10"
  caching            = "ReadWrite"
  count = 2
}

## To be done only on ADMIN for NFS VMs add a 100Gb for containers
resource "azurerm_managed_disk" "caasp4-admin-datadisks" {
  name                 = "caasp4tf-${var.list-nodes[count.index]}-datadisk1"
  location              =  var.azure-region
  resource_group_name   = azurerm_resource_group.caasp4tf-eu-rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 100
  count = 1
}

resource "azurerm_virtual_machine_data_disk_attachment" "caasp4-admin-datadisks" {
  managed_disk_id    = azurerm_managed_disk.caasp4-admin-datadisks[count.index].id
  virtual_machine_id = azurerm_virtual_machine.caasp4tf-VMs[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
  count = 1
}
# Mount disks & Launch the NFS Server on Admin node.
resource "null_resource" "remote-exec-admin" {
      provisioner "remote-exec" {
      connection {
      agent       = false
      timeout     = "30m"
      user     = "jmlambert"
      host     = azurerm_public_ip.caasp4tf-publicip[0].ip_address
      private_key = file(var.ssh_private_key_jml)
    }
  
    inline = [
      "chmod +x /tmp/nfsserver.sh",   "sudo /tmp/nfsserver.sh"
    ]
    }
    depends_on = [azurerm_virtual_machine_data_disk_attachment.caasp4-admin-datadisks[0]]
}
# Mount data disks on nodes.
resource "null_resource" "remote-exec-nodes" {
provisioner "remote-exec" {
connection {
      agent       = false
      timeout     = "30m"
      user     = "jmlambert"
      host     = azurerm_public_ip.caasp4tf-publicip[2+count.index].ip_address
      private_key = file(var.ssh_private_key_jml)
    }
    inline = [
      "chmod +x /tmp/nfsserver.sh",   "sudo /tmp/nfsserver.sh"
    ]
}
    count = 2
    depends_on = [azurerm_virtual_machine_data_disk_attachment.caasp4-datadisks]
    
}


