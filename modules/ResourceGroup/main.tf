resource "azurerm_resource_group" "resourcegroup" {
  for_each = var.rgs
  name     = each.key
  location = each.value.location
}

output "rg_ids" {
  value = { for key, value in azurerm_resource_group.resourcegroup: value.name => value.id } 
}



resource "azurerm_storage_account" "storageaccount" {
  for_each                 = var.stg_details
  name                     = "${each.value.name}stgacount"
  resource_group_name      = each.value.name
  location                 = each.value.location
  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type
}
