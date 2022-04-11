resource "oci_identity_compartment" "oke" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for Terraform resources."
  name           = var.compartment_name
  enable_delete  = true
}

module "oke" {
  source = "oracle-terraform-modules/oke/oci"

  api_fingerprint      = var.fingerprint
  api_private_key_path = var.private_key_path
  compartment_id       = oci_identity_compartment.oke.id

  region              = var.region
  tenancy_id          = var.tenancy_ocid
  user_id             = var.user_ocid
  existing_key_id     = ""
  image_signing_keys  = []
  ssh_public_key_path = var.ssh_public_key_path
  operator_enabled    = false
  bastion_enabled     = false

  kubernetes_version = "v1.20.8"

  node_pools = {
    np1 = {
      boot_volume_size = 50
      node_pool_size   = 2
      ocpus            = 2
      shape            = "VM.Standard.A1.Flex"
      memory           = 12
    }
  }
}
