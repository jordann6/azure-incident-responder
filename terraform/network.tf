# Minimal network for the demo target VM. No public IP: CPU is driven for the
# demo with `az vm run-command`, so the VM needs no inbound exposure. The NSG
# denies inbound by default (only Azure platform rules apply).

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "target" {
  name                 = "snet-target"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 0)]
}

resource "azurerm_network_security_group" "target" {
  name                = "nsg-${var.project}-target"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "target" {
  subnet_id                 = azurerm_subnet.target.id
  network_security_group_id = azurerm_network_security_group.target.id
}

resource "azurerm_network_interface" "target" {
  name                = "nic-${var.project}-target"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.target.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "random_password" "vm_admin" {
  length  = 20
  special = true
}

resource "azurerm_linux_virtual_machine" "target" {
  name                            = "vm-${var.project}-target"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.target_vm_size
  admin_username                  = var.admin_username
  admin_password                  = random_password.vm_admin.result
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.target.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    environment = "demo"
    managedBy   = "terraform"
  }
}
