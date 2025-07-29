/*resource "oci_database_autonomous_database" "webapp_db" {
  compartment_id           = var.compartment_id
  cpu_core_count           = 1
  data_storage_size_in_tbs = 1
  db_name                  = "webappdb"
  display_name             = "WebAppDB"
  admin_password           = var.admin_password
  license_model            = "LICENSE_INCLUDED"
  db_workload              = "OLTP"
  is_free_tier             = false
  subnet_id                = var.subnet_id
  nsg_ids                  = [oci_core_network_security_group.db_nsg.id]
  private_endpoint_label   = "dbprivate"
  is_auto_scaling_enabled = false
  is_mtls_connection_required = false
}*/

resource "oci_database_autonomous_database" "webapp_adb" {
  compartment_id           =  var.compartment_id
  db_name                  = "WEBAPPADB"
  display_name             = "WebAppADB"
  admin_password           = var.admin_password
  cpu_core_count           = 1#Free tier eligible
  data_storage_size_in_tbs = 1 # Free tier eligible
  
  license_model            = "LICENSE_INCLUDED"
  is_free_tier             = true
  is_auto_scaling_enabled  = false

 # subnet_id                = var.subnet_id
  
 # nsg_ids                  = [oci_core_network_security_group.adb_nsg.id]
  
}
/*resource "oci_database_db_system" "webapp_dbcs" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  display_name        = "webapp-dbcs"
  hostname            = "webappdbcs"
  shape               = "VM.Standard2.1"  # ✅ Always Free eligible
  subnet_id           = var.subnet_id

  database_edition    = "STANDARD_EDITION"
  ssh_public_keys     = [var.ssh_public_key]
  time_zone           = "UTC"

  db_home {
    display_name = "webappdbhome"
    database {
      admin_password = var.admin_password
      db_name        = "WEBAPPDB"
      character_set  = "AL32UTF8"
      ncharacter_set = "AL16UTF16"
    }
    db_version = "19.0.0.0"
  }
}
*/
resource "oci_core_network_security_group" "adb_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_subnet.private_subnet.vcn_id
  display_name   = "db-nsg"
}

resource "oci_core_network_security_group_security_rule" "db_nsg_rule" {
  network_security_group_id = oci_core_network_security_group.adb_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = cidrsubnet(data.oci_core_vcn.vcn.cidr_block, 8, 0)
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 1521
      min = 1521
    }
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}
data "oci_core_subnet" "private_subnet" {
  subnet_id = var.subnet_id
}

data "oci_core_vcn" "vcn" {
  vcn_id = data.oci_core_subnet.private_subnet.vcn_id
}

output "db_host" {
#value =  regex("HOST=([^)]+)", oci_database_autonomous_database.webapp_adb.connection_strings[0].high)[0]
value = split(":", oci_database_autonomous_database.webapp_adb.connection_strings[0].high)[0]
}


output "db_service" {
value = split("/", oci_database_autonomous_database.webapp_adb.connection_strings[0].high)[1]
}