
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {
  default = "us-phoenix-1"
}

variable "compartment_id" {}
variable "vcn_cidr_block" {
  default = "10.0.0.0/16"
}

variable "ssh_public_key" {}
variable "db_admin_password" {}
variable "db_user" {
  default = "app_user"
}
variable "db_password" {}
#variable "subnet_id" {}
