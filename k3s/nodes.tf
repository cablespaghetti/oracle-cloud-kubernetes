resource "random_string" "cluster_token" {
  length           = 48
  special          = true
  number           = true
  lower            = true
  upper            = true
  override_special = "^@~*#%/.+:;_"
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

data "cloudinit_config" "kubernetes_control_plane" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "control_plane.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/cloudinit.tftpl", {
      node_role     = "control-plane",
      k3s_version   = var.k3s_version
      k3s_token     = random_string.cluster_token.result
      lb_ip_address = oci_load_balancer_load_balancer.kubernetes.ip_address_details[0].ip_address
    })
  }
}

resource "oci_core_instance_configuration" "kubernetes_control_plane" {
  depends_on = [
    oci_identity_tag.instance_group
  ]
  compartment_id = oci_identity_compartment.kubernetes.id
  display_name   = local.resource_name

  instance_details {
    instance_type = "compute"

    launch_details {

      agent_config {
        is_management_disabled = "false"
        is_monitoring_disabled = "false"

        plugins_config {
          desired_state = "DISABLED"
          name          = "Vulnerability Scanning"
        }

        plugins_config {
          desired_state = "ENABLED"
          name          = "Compute Instance Monitoring"
        }

        plugins_config {
          desired_state = "ENABLED"
          name          = "Bastion"
        }
      }

      availability_domain = data.oci_identity_availability_domain.ad.name
      compartment_id      = oci_identity_compartment.kubernetes.id
      defined_tags        = { "Security.Instance-Group" = local.resource_name }

      create_vnic_details {
        assign_public_ip = false
        subnet_id        = oci_core_subnet.private.id
        nsg_ids          = [oci_core_network_security_group.kubernetes.id]
      }

      display_name = local.resource_name

      metadata = {
        ssh_authorized_keys = file(var.ssh_public_key_path)
        user_data           = data.cloudinit_config.kubernetes_control_plane.rendered
      }

      shape = "VM.Standard.A1.Flex"
      shape_config {
        memory_in_gbs = "6"
        ocpus         = "1"
      }
      source_details {
        image_id    = data.oci_core_images.kubernetes.images.0.id
        source_type = "image"
      }
    }
  }
  freeform_tags = local.freeform_tags
}

resource "oci_core_instance_pool" "kubernetes_control_plane" {
  depends_on = [
    oci_identity_dynamic_group.kubernetes_control_plane,
    oci_identity_policy.kubernetes_control_plane
  ]

  lifecycle {
    create_before_destroy = true
  }

  display_name              = local.resource_name
  compartment_id            = oci_identity_compartment.kubernetes.id
  instance_configuration_id = oci_core_instance_configuration.kubernetes_control_plane.id

  placement_configurations {
    availability_domain = data.oci_identity_availability_domain.ad.name
    primary_subnet_id   = oci_core_subnet.private.id
  }

  load_balancers {
    load_balancer_id = oci_load_balancer_load_balancer.kubernetes.id
    backend_set_name = oci_load_balancer_backend_set.kubernetes_control_plane.name
    port             = 6443
    vnic_selection   = "PrimaryVnic"
  }

  load_balancers {
    load_balancer_id = oci_load_balancer_load_balancer.kubernetes.id
    backend_set_name = oci_load_balancer_backend_set.kubernetes_https.name
    port             = 443
    vnic_selection   = "PrimaryVnic"
  }

  size = 3

  freeform_tags = local.freeform_tags
}

data "cloudinit_config" "kubernetes_worker" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "control_plane.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/cloudinit.tftpl", {
      node_role     = "worker",
      k3s_version   = var.k3s_version
      k3s_token     = random_string.cluster_token.result
      lb_ip_address = oci_load_balancer_load_balancer.kubernetes.ip_address_details[0].ip_address
    })
  }
}

resource "oci_core_instance_configuration" "kubernetes_worker" {
  depends_on = [
    oci_identity_tag.instance_group
  ]
  compartment_id = oci_identity_compartment.kubernetes.id
  display_name   = local.resource_name

  instance_details {
    instance_type = "compute"

    launch_details {

      agent_config {
        is_management_disabled = "false"
        is_monitoring_disabled = "false"

        plugins_config {
          desired_state = "DISABLED"
          name          = "Vulnerability Scanning"
        }

        plugins_config {
          desired_state = "ENABLED"
          name          = "Compute Instance Monitoring"
        }

        plugins_config {
          desired_state = "ENABLED"
          name          = "Bastion"
        }
      }

      availability_domain = data.oci_identity_availability_domain.ad.name
      compartment_id      = oci_identity_compartment.kubernetes.id
      defined_tags        = { "Security.Instance-Group" = local.resource_name }

      create_vnic_details {
        assign_public_ip = false
        subnet_id        = oci_core_subnet.private.id
        nsg_ids          = [oci_core_network_security_group.kubernetes.id]
      }

      display_name = local.resource_name

      metadata = {
        ssh_authorized_keys = file(var.ssh_public_key_path)
        user_data           = data.cloudinit_config.kubernetes_worker.rendered
      }

      shape = "VM.Standard.A1.Flex"
      shape_config {
        memory_in_gbs = "6"
        ocpus         = "1"
      }
      source_details {
        image_id    = data.oci_core_images.kubernetes.images.0.id
        source_type = "image"
      }
    }
  }
  freeform_tags = local.freeform_tags
}

resource "oci_core_instance_pool" "kubernetes_worker" {
  lifecycle {
    create_before_destroy = true
  }

  display_name              = "${var.environment_name}-worker"
  compartment_id            = oci_identity_compartment.kubernetes.id
  instance_configuration_id = oci_core_instance_configuration.kubernetes_worker.id

  placement_configurations {
    availability_domain = data.oci_identity_availability_domain.ad.name
    primary_subnet_id   = oci_core_subnet.private.id
  }

  size = 1

  freeform_tags = local.freeform_tags
}
