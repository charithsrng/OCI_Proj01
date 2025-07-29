variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}
variable "subnet_id" {}
variable "admin_password" {}
variable "ssh_public_key" { 
    description = "SSH public key for accessing the DBCS host"
    type = string
    }