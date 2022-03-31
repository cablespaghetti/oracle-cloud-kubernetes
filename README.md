# Kubernetes for free using Oracle Cloud Always Free resources

Uses Terraform and Oracle's modules, to create a Kubernetes cluster using only "Always Free" resources on Oracle Cloud using their Container Engine For Kubernetes service and Ampere ARM nodes. You can then choose to install a number of services on the new cluster:

* [Longhorn](https://longhorn.io) for replicated persistent storage on the node root volumes. You can also configure backups to S3 compatible object storage if you like.
* [Cert Manager](https://cert-manager.io/) for TLS certificate generation. I use this for Ingress and there is YAML provided for a self-signed cluster provisioner which is fine as I'm using Cloudflare.
* [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/) using the Always Free 10Mb Load Balancer for web traffic ingress into the cluster.
* [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) to deployment Prometheus and AlertManager for monitoring and alerting.
* [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server) to allow pod autoscaling and certain metrics to function correctly.
* [Grafana Loki](https://grafana.com/oss/loki/) for lightweight log aggregation.

## Creating the cluster

### Initial configuration

You will need an account on [Oracle Cloud](https://cloud.oracle.com). You'll be given some credits (£250 in the UK) initially but you shouldn't see them being used by anything in this repository; everything should be covered by the [Always Free resourcs](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) and OKE is free anyway.

When your account is activated you'll need to get some details to populate the `terraform/terraform.tfvars` file, which are used to authentiate to your account. The information of how to get these details are in [Oracle's Documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformproviderconfiguration.htm#configuring_the_terraform_provider).

At the end of the trial period you will need to convert your account to a paid account rather than leaving it as a free tier account. This is because whilst OKE is free, it is not supported (yet) on a free account. [The documentation](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier.htm) also says that the Ampere instances will be terminated and need reprovisioning, although I didn't encounter this.

I recommend you setup [Budgets](https://docs.oracle.com/en-us/iaas/Content/Billing/Concepts/budgetsoverview.htm) on your account to ensure you get alerted if you are running up a bill. Unfortunately I am currently being billed £0.05 a day for the boot volume of one of my nodes, but I can live with that. This might be down to the many things I've tried on my account and I'd be interested to hear if others also get the same issue.

### Applying the Terraform

With the account created and `terraform.tfvars` file populated, creating your cluster should then be as simple as opening a terminal in the `terraform` directory and running `terraform init` followed by `terraform apply`.

If you want to use [Remote State](https://www.terraform.io/docs/language/state/remote.html) for your Terraform state file you will need to perform additional configuration. I am storing mine in OCI Object Storage using a Pre Authenticated Request URL, using the method in [this medium post](https://medium.com/oracledevs/storing-terraform-remote-state-to-oracle-cloud-infrastructure-object-storage-b32fe7402781). You could also use Oracle Cloud's [Resource Manager](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm) managed Terraform service which has just released support for Terraform 1.0.

Note: Unfortunately the Terraform Provider doesn't have a darwin_arm64 build, so if you're on an M1 Mac you'll need to download the amd64 binary of Terraform to run under Rosetta 2 for the time being. [Here is the GitHub Issue](https://github.com/terraform-providers/terraform-provider-oci/issues/1322).

## Connecting to your Kubernetes Cluster

The Terraform creates a `generated` directory containing your kubeconfig file. You can either use this where it is by running `export KUBECONFIG=/path/to/generated/kubeconfig` or copy it to the default path used by `kubectl` at `~/.kube/config`.

At this point you will need to make sure you have the [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm) installed, as that is used for authentication to your new cluster.

You should now be able to run commands like `kubectl get no` and see you have a cluster up and running with two nodes.

## Installing services on the cluster

The [OKE Terraform module](https://github.com/oracle-terraform-modules/terraform-oci-oke) this repository uses has many options; one of which is to install a few things to to your cluster such as Metrics Server. However it does this through the use of Bastion and Operator instances. As we don't want to waste our money on these instances when the OKE API is accessible straight from the Internet, we'll just install the services we need from the local machine instead.

I am partial to a tool called [helmfile](https://github.com/roboll/helmfile) which makes it possible to manage Helm releases in a YAML configuration file. You will need this utility installed to apply the configuration in the `services` directory. Installation should be as simple as running `helmfile apply` in the services directory followed by `kubectl apply -f yaml/`.

If you want the emails from Prometheus AlertManager to reach you, you will need to reconfigure the SMTP details in the `values/kube-prometheus-stack.yaml` file. These credentials will then obviously be stored in plain text in Git, so I recommend looking into something like the [helm-secrets integration in Helmfile](https://github.com/roboll/helmfile#environment-secrets).

## Example Ingress Configuration

When you deploy services on the cluster you can make them web-facing with a self-signed certificate using a configuration like this:

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: wordpress
  labels:
    app: wordpress
  annotations:
    cert-manager.io/cluster-issuer: selfsigned
    nginx.ingress.kubernetes.io/from-to-www-redirect: "true"
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: wordpress
          servicePort: 80
  tls:
  - hosts:
    - example.com
    secretName: wordpress-cert
```
