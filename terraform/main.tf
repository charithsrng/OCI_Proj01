
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

module "network" {
  source       = "./modules/network"
  compartment_id = var.compartment_id
  vcn_cidr_block = var.vcn_cidr_block
}

module "database" {
  source         = "./modules/database"
  compartment_id = var.compartment_id
  subnet_id      = module.network.private_subnet_id
  admin_password = var.db_admin_password
  ssh_public_key = var.ssh_public_key
}

module "compute" {
  source         = "./modules/compute"
  compartment_id = var.compartment_id
  subnet_id      = module.network.public_subnet_id
  ssh_public_key = var.ssh_public_key
  db_host        = module.database.db_host
  db_service     = module.database.db_service
  db_user        = var.db_user
  db_password    = var.db_password
}