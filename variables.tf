variable "ssh_public_key_path" {
  description = "The filesystem path of an SSH public key to authorised for host authentication"
  default     = "~/.ssh/id_rsa.pub"
}

variable "region" {
  description = "The OCI region we're using"
  default     = "uk-london-1"
}

variable "tenancy_ocid" {
  description = "The OCID of the parent tenancy in which we're creating a compartment"
}

variable "environment_name" {
  description = "The name to give the OCI compartment"
  default     = "kubernetes"
}

variable "cidr_block" {
  description = "The CIDR /16 block to use for the VCN"
  default     = "10.200.0.0"
}

locals {
  freeform_tags = {
    "provisioner" = "terraform"
    "environment" = var.environment_name
  }
  vcn_cidr     = "${var.cidr_block}/16"
  private_cidr = cidrsubnet(local.vcn_cidr, 2, 0)
  public_cidr  = cidrsubnet(local.vcn_cidr, 2, 1)
  bastion_cidr = cidrsubnet(local.vcn_cidr, 8, 254)
}
