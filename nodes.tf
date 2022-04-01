data "oci_core_images" "kubernetes" {
  compartment_id           = oci_identity_compartment.kubernetes.id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_network_security_group" "kubernetes" {
  compartment_id = oci_identity_compartment.kubernetes.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "kubernetes"
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = local.bastion_cidr
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_apiserver" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.kubernetes.id
  source_type               = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_metrics" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.kubernetes.id
  source_type               = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      min = 10250
      max = 10250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_flannel" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 17
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.kubernetes.id
  source_type               = "NETWORK_SECURITY_GROUP"
  udp_options {
    destination_port_range {
      min = 8472
      max = 8472
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_ingress_etcd" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = 6
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.kubernetes.id
  source_type               = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      min = 2379
      max = 2380
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes_egress" {
  network_security_group_id = oci_core_network_security_group.kubernetes.id
  protocol                  = "all"
  direction                 = "EGRESS"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

locals {
  oci_cloud_controller_manager_config = base64encode(<<EOT
useInstancePrincipals: true
compartment: ${oci_identity_compartment.kubernetes.id}
vcn: ${module.vcn.vcn_id}
loadBalancer:
  subnet1: ${oci_core_subnet.public.id}
  securityListManagementMode: All
EOT
  )
}

data "cloudinit_config" "kubernetes_control_plane" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "control_plane.sh"
    content_type = "text/x-shellscript"
    content      = <<EOT
#!/bin/bash
# Disable and stop firewalld as per k3s docs
systemctl disable firewalld --now

# Install htop (because I like it...) and upgrade everything
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf upgrade -y
dnf install -y htop

# Download and install OCI Cloud Controller Manager Manifests
mkdir -p /var/lib/rancher/k3s/server/manifests
curl -sfLo /var/lib/rancher/k3s/server/manifests/oci-cloud-controller-manager-rbac.yaml https://raw.githubusercontent.com/oracle/oci-cloud-controller-manager/v0.13.0/manifests/cloud-controller-manager/oci-cloud-controller-manager-rbac.yaml
curl -sfLo /var/lib/rancher/k3s/server/manifests/oci-cloud-controller-manager.yaml https://raw.githubusercontent.com/oracle/oci-cloud-controller-manager/v0.13.0/manifests/cloud-controller-manager/oci-cloud-controller-manager.yaml

# Work around bug in node selector in manifest
sed -i 's/node-role.kubernetes.io\/master: ""/node-role.kubernetes.io\/master: "true"/' /var/lib/rancher/k3s/server/manifests/oci-cloud-controller-manager.yaml

# Install K3S
export INSTALL_K3S_EXEC="server --disable traefik --disable servicelb --disable-cloud-controller"
export INSTALL_K3S_CHANNEL=latest
curl -sfL https://get.k3s.io | sh -

EOT
  }
  part {
    filename     = "oci_cloud_controller_manager_secret.yaml"
    content_type = "text/cloud-config"
    content      = <<EOT
write_files:
- content: |
    apiVersion: v1
    kind: Secret
    metadata:
      name: oci-cloud-controller-manager
      namespace: kube-system
    data:
      cloud-provider.yaml: ${local.oci_cloud_controller_manager_config}
  path: /var/lib/rancher/k3s/server/manifests/oci-cloud-controller-manager-secret.yaml
EOT
  }
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

resource "oci_core_instance" "kubernetes_control_plane" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = oci_identity_compartment.kubernetes.id
  shape               = "VM.Standard.A1.Flex"
  display_name        = "kubernetes-control-plane"
  shape_config {
    memory_in_gbs = 24
    ocpus         = 4
  }
  source_details {
    source_id   = data.oci_core_images.kubernetes.images.0.id
    source_type = "image"
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
    nsg_ids          = [oci_core_network_security_group.kubernetes.id]
  }
  # prevent the instance from destroying and recreating itself if the image ocid changes 
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = data.cloudinit_config.kubernetes_control_plane.rendered
  }
}
