

resource "oci_core_virtual_network" "vcn" {
  cidr_block     = var.vcn_cidr_block
  compartment_id = var.compartment_id
  display_name   = "webapp-vcn"
  dns_label      = "webappvcn" 
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "webapp-igw"
}

resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "public-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_security_list" "public_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "public-security-list"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      max = 22
      min = 22
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      max = 80
      min = 80
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      max = 5000
      min = 5000
    }
  }
}

resource "oci_core_subnet" "public_subnet" {
  cidr_block        = cidrsubnet(var.vcn_cidr_block, 8, 0)
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_virtual_network.vcn.id
  display_name      = "public-subnet"
  route_table_id    = oci_core_route_table.public_route_table.id
  security_list_ids = [oci_core_security_list.public_security_list.id]
  dhcp_options_id   = oci_core_virtual_network.vcn.default_dhcp_options_id
}

resource "oci_core_subnet" "private_subnet" {
  cidr_block        = cidrsubnet(var.vcn_cidr_block, 8, 1)
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_virtual_network.vcn.id
  display_name      = "private-subnet"
  prohibit_public_ip_on_vnic = true
  dns_label = "privsubnet"
  dhcp_options_id   = oci_core_virtual_network.vcn.default_dhcp_options_id
}

