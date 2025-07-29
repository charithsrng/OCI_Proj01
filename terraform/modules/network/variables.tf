variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}
variable "vcn_cidr_block" {
  default = "10.0.0.0/16"
}