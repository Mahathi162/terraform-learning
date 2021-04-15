resource "azurerm_resource_group" "rg1" {
  name     = "${local.gid}-rg"
  location = "${local.region}"
  tags = local.tags
}
resource "azurerm_virtual_network" "vnetwork" {
  name                = "${local.gid}-vnet-stg"
  address_space       = ["10.0.0.0/16"]
  #dns_servers         = ["8.8.8.8", "8.8.4.4"]
  #location            = "${azurerm_resource_group.rg1.location}"
  resource_group_name = "${azurerm_resource_group.rg1.name}"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${local.gid}-nsg-stg"
  location            = "${azurerm_resource_group.rg1.location}"   
  resource_group_name = "${azurerm_resource_group.rg1.name}"
}

resource "azurerm_subnet" "mysubnet" {
  name                 = "${local.gid}-snet-stg"
  resource_group_name  = "${azurerm_resource_group.rg1.name}"
  virtual_network_name = "${azurerm_virtual_network.vnetwork.name}"
  #network_security_group_id = "${azurerm_network_security_group.nsg.id}"
  address_prefix       = "10.0.3.0/24"
}
resource "azurerm_public_ip" "publicip" {
  count               = local.class_size
  name                = "${local.gid}-control-ip-${count.index}"
  location            = "${azurerm_resource_group.rg1.location}"
  resource_group_name = "${azurerm_resource_group.rg1.name}"
  allocation_method   = "Dynamic"
  tags = local.tags
}
# connects your VM to a given virtual network, public IP address, and network security group
resource "azurerm_network_interface" "NIC" {
  count               = local.class_size
  name                = "${local.gid}-staging-nic-${count.index}"
  location            = "${azurerm_resource_group.rg1.location}"
  resource_group_name = "${azurerm_resource_group.rg1.name}"

  ip_configuration {
    name                          = "NICconfiguration"
    subnet_id                     = "${azurerm_subnet.mysubnet.id}"
    public_ip_address_id          = "${azurerm_public_ip.publicip[count.index].id}"
    private_ip_address            = "10.0.3.${count.index + 4}"
    private_ip_address_allocation = "Static"
  }
}

#resource "azurerm_linux_virtual_machine" "staging-vm" {
  count                 = local.class_size
  name                  = "${local.gid}-staging-vm-${count.index}"
  location              = "${azurerm_resource_group.rg1.location}"
  resource_group_name   = "${azurerm_resource_group.rg1.name}"
  network_interface_ids = [
    "${azurerm_network_interface.NIC[count.index].id}"
  ]
  vm_size               = "Standard_DS1_v2"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "${local.gid}-staging-vm-osdisk-${count.index}"
    caching           = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  
    computer_name  = "myvm"
    admin_username = "azureuser"
    disable_password_authentication = true

  os_profile_linux_config {
   disable_password_authentication = false
 }
 # Create (and display) an SSH key
  resource "tls_private_key" "example_ssh" {
    algorithm = "RSA"
    rsa_bits = 4096
  }
  output "tls_private_key" { value = tls_private_key.example_ssh.private_key_pem }
    admin_ssh_key {
          username       = "azureuser"
          public_key     = tls_private_key.example_ssh.public_key_openssh
    }
