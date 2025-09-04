# Subnet Data source
data "azurerm_subnet" "data_subnet" {
  for_each             = var.vms
  name                 = each.value.subnet_name
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.resource_group_name
}


# Public IP
resource "azurerm_public_ip" "public_ip" {
  for_each            = { for key, value in var.vms : key => value if value.enable_public_ip == "Yes" }
  
  # key is the VM name, value is the VM details  we can set it like vm  => vm_detials # or use each.key and each.value

  # This will create a public IP only for VMs where enable_public_ip is set to "Yes"
  
  name                = "public-ip-${each.key}"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  allocation_method   = "Static"
  sku                 = "Standard"

}


# Network_Interface_Card
resource "azurerm_network_interface" "nic" {
  for_each            = var.vms
  name                = "${each.key}-nic"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location


  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.data_subnet[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = contains(keys(azurerm_public_ip.public_ip), each.key) ? azurerm_public_ip.public_ip[each.key].id :  null
  }
}



# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  for_each            = var.vms
  name                = "nsg-${each.key}"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location



  dynamic "security_rule" {
    for_each = each.value.inbound_open_ports
    content {
      
    name                       = "open_ports-${security_rule.value}"
    priority                   = ceil((security_rule.value % 9) + 130) # ceil is used to round up the value to the nearest whole number
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = security_rule.value
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }
  }
}


# NIC association with NSG
resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  for_each                  = var.vms
  network_interface_id      = azurerm_network_interface.nic[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

#Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  for_each                        = var.vms
  name                            = each.key # we can use same name in VM name field
  resource_group_name             = each.value.resource_group_name
  location                        = each.value.location
  size                            = each.value.size
  admin_username                  = each.value.admin_username
  admin_password                  = each.value.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic[each.key].id]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


   source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

}




# resource "null_resource" "remote_exec" {
#   depends_on = [azurerm_linux_virtual_machine.vm, azurerm_public_ip.public_ip]  # This ensures that the remote-exec provisioner runs after the VM and Public IP are created
 
#   #for_each = var.vms
#    for_each = { for key, value in var.vms : key => value if value.enable_public_ip == "Yes" }
#   connection {
#     type        = "ssh"
#     host        =  azurerm_public_ip.public_ip[each.key].ip_address #contains(keys(azurerm_public_ip.public_ip), each.key) ? azurerm_public_ip.public_ip[each.key].ip_address :  null
#     user        = each.value.admin_username
#     password    = each.value.admin_password
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo apt update",
#       "sudo apt install nginx -y",
#       "sleep 10"
#     ]
#   }
  
# }


output "vm_public_ips" {
  value = { for k, v in azurerm_public_ip.public_ip : k => v.ip_address }
}

