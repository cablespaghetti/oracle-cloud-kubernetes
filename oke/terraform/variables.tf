variable "region" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "ssh_public_key_path" {}
variable "compartment_name" {
  default = "kubernetes"
}

