# Kubernetes using Oracle Cloud Always Free resources

This repository contains two methods of getting a working Kubernetes cluster on Oracle Cloud using their Always Free resources.

1. Using their managed Kubernetes service: Oracle Container Engine for Kubernetes (OKE)
2. Using k3s with a highly available (embedded etcd) control plane

In both cases the nodes will be of the Ampere ARM64 variety, because you get 4 cores and 24GB RAM worth of nodes this way. You only get a couple of 1 core 1GB RAM nodes using x86 processors.

I make no promises to keep this repo up to date, but it should serve as a good example of how to get started with Kubernetes on Oracle Cloud Infrastructure.

## Creating the cluster

### Initial configuration

You will need an account on [Oracle Cloud](https://cloud.oracle.com). You'll be given some credits (£250 in the UK) initially but you shouldn't see them being used by anything in this repository; everything should be covered by the [Always Free resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) and OKE is free anyway.

When your account is activated you'll need to install and configure the [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm) get some details to populate the `terraform.tfvars` file, which are used to authentiate to your account. The information of how to get these details are in [Oracle's Documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformproviderconfiguration.htm#configuring_the_terraform_provider).

At the end of the trial period you will need to convert your account to a paid account rather than leaving it as a free tier account. This is because whilst OKE is free, it is not supported (yet) on a free account. [The documentation](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier.htm) also says that the Ampere instances will be terminated and need reprovisioning, although I didn't encounter this.

I recommend you setup [Budgets](https://docs.oracle.com/en-us/iaas/Content/Billing/Concepts/budgetsoverview.htm) on your account to ensure you get alerted if you are running up a bill. Unfortunately I am currently being billed £0.05 a day for the boot volume of one of my nodes, but I can live with that. This might be down to the many things I've tried on my account and I'd be interested to hear if others also get the same issue.

### Applying the Terraform

With the account created and `terraform.tfvars` file populated, creating your cluster should then be as simple as opening a terminal in the relevant directory and running `terraform init` followed by `terraform apply`.

If you want to use [Remote State](https://www.terraform.io/docs/language/state/remote.html) for your Terraform state file you will need to perform additional configuration. I am storing mine in OCI Object Storage using a Pre Authenticated Request URL, using the method in [this medium post](https://medium.com/oracledevs/storing-terraform-remote-state-to-oracle-cloud-infrastructure-object-storage-b32fe7402781). You could also use Oracle Cloud's [Resource Manager](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm) managed Terraform service.

## Connecting to your Kubernetes Cluster
### OKE

The Terraform creates a `generated` directory containing your kubeconfig file. You can either use this where it is by running `export KUBECONFIG=/path/to/generated/kubeconfig` or copy it to the default path used by `kubectl` at `~/.kube/config`.

At this point you will need to make sure you have the [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm) installed, as that is used for authentication to your new cluster.

You should now be able to run commands like `kubectl get no` and see you have a cluster up and running with two nodes.

### k3s

You will need to use Oracle managed bastion service (already configured by the terraform) to SSH into one of the control plane nodes. The username will be `opc`. You will find a kubeconfig file in `/etc/rancher/k3s/k3s.yaml` but for it to work locally you will need to change the IP address to that of your Load Balancer using https on port 6443.

You will see there are 4 nodes; 3 control plane and 1 worker. All with 1 CPU core and 6 GB RAM.
