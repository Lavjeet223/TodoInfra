module "rg" {
  source = "../../modules/ResourceGroup"
  rgs    = var.rgs
  stg_details = var.stg_details
}


module "vnet" {
  depends_on = [module.rg]
  source     = "../../modules/Networking"
  vnets      = var.vnets
  subnets    = var.subnets
}



# module "vm" {
#   depends_on = [module.vnet]
#   source     = "../../modules/LinuxVirtualMachine"
#   vms        = var.vms
# }




# module "servers_dbs" {
#   depends_on = [module.vm]
#   source     = "../../modules/database"
#   servers_dbs = var.servers_dbs
# }
