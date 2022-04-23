resource "oci_identity_compartment" "oke" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for Terraform resources."
  name           = var.compartment_name
  enable_delete  = true
}

module "oke" {
  source = "oracle-terraform-modules/oke/oci"

  compartment_id = oci_identity_compartment.oke.id

  region              = var.region
  home_region         = var.region
  tenancy_id          = var.tenancy_ocid
  ssh_public_key_path = var.ssh_public_key_path
  create_bastion_host = false
  create_operator     = false
  kubernetes_version  = "v1.22.5"
  subnets = {
    bastion  = { netnum = 0, newbits = 13 }
    operator = { netnum = 1, newbits = 13 }
    cp       = { netnum = 2, newbits = 13 }
    int_lb   = { netnum = 16, newbits = 11 }
    pub_lb   = { netnum = 17, newbits = 11 }
    workers  = { netnum = 1, newbits = 2 }
    fss      = { netnum = 18, newbits = 11 }
  }
  node_pools = {
    np1 = {
      boot_volume_size = 50
      node_pool_size   = 2
      ocpus            = 2
      shape            = "VM.Standard.A1.Flex"
      memory           = 12
    }
  }
  providers = {
    oci.home = oci
  }
}
