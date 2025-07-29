resource "oci_core_instance" "webapp_instance" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad.name
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "webapp-instance"

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
    #ostname_label   = "webapp"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/user_data.sh", {
      db_host     = var.db_host
      db_service  = var.db_service
      db_user     = var.db_user
      db_password = var.db_password
    }))
  }
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.compartment_id
  ad_number      = 1
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_id
  operating_system        = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                   = "VM.Standard.E2.1.Micro"
  sort_by                 = "TIMECREATED"
  sort_order              = "DESC"
}

resource "oci_core_network_security_group" "webapp_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_subnet.public_subnet.vcn_id
  display_name   = "webapp-nsg"
}

resource "oci_core_network_security_group_security_rule" "webapp_nsg_rule_http" {
  network_security_group_id = oci_core_network_security_group.webapp_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 5000
      min = 5000
    }
  }
}

data "oci_core_subnet" "public_subnet" {
  subnet_id = var.subnet_id
}

output "instance_public_ip" {
  value = oci_core_instance.webapp_instance.public_ip
}