provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  # version = "1.44.0"
  subscription_id = "c90e3d0d-7080-4628-b93b-0107fa7a76e7"
}

locals {
  tags ={environment = "Staging"}
  class_size = 1
  region = "North Central US"
  gid = "staging"
  vm_username = "mm185548"
  vm_password = "M@h@thi"
}
