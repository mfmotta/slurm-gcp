# Slurm on Google Cloud Platform

Notice: This is a branch where I keep my changes to master forked from [SchedMD/slurm-gcp](https://github.com/SchedMD/slurm-gcp)

## Setting up a cluster on GCP

This is a quick guide to set up a GPU cluster on GCP.

Requirements:

    - a [Google Cloud Platform project](https://console.cloud.google.com/freetrial/)
    - (Terraform)[What is Infrastructure as Code with Terraform?] installed

For more details and a starting tutorial, please refer to [Build Infrastructure - Terraform GCP Example](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build)


1 - Fork or clone [SchedMD/slurm-gcp](https://github.com/SchedMD/slurm-gcp)

2 - In [slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/cloud/full](https://github.com/SchedMD/slurm-gcp/tree/master/terraform/slurm_cluster/examples/slurm_cluster/cloud/full), edit the files ``example.tfvars``, ``variables.tf``, and ``main.tf``. 

Our cluster has the following configuration (we only list some of the variables):

**Login node:**

disk_size_gb             = 16

disk_type                = "pd-standard"

machine_type             = "n1-standard-2"

source_image             = "us-central1-docker.pkg.dev/your-project-id/your-repo/your-image:your-image-tag"

Notice this considers you have uploaded an image to the repository ``your-repo`` in GCP's [Artifact Registry](https://cloud.google.com/artifact-registry/docs/docker/pushing-and-pulling). You can also use a base image from other registries, e.g. https://github.com/SchedMD/slurm-gcp/blob/master/docs/images.md.

---    

**Controller node:**

disk_size_gb           = 16

disk_type              = "pd-standard"

machine_type           = "n1-standard-4"

---

**Partitions:**
<br>

 - **partition #1** 

    node_count_dynamic_max = 2 

    disk_size_gb           = 16

    disk_type              = "pd-standard"

    machine_type           = "c2-standard-4"

    preemptible            = true  

 - **partition #2**

    partition_conf = {
        SuspendTime          = 120
    }

    node_count_dynamic_max = 2

    disk_size_gb           = 16

    disk_type              = "pd-standard"

    gpu = {
        count = 1
        type  = "nvidia-tesla-t4"
    }

    machine_type           = "n1-standard-4"

    preemptible            = true 

<br>

We use a single gpu per node and a maximum node count of two. We also use preemptible machines and a reduced SuspendTime to reduce costs.



Notice we have included the variable ``credentials_file = "path/to/your-service-account-key.json"``-- see [Create a service account key](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#:~:text=A%20GCP%20service%20account%20key%3A%20Create%20a%20service%20account%20key).

3 - To produce a plan for your infrastructure, run

```
terraform init
terraform validate
terraform plan -var-file=example.tfvars -out terraform.tfplan
```
4 - Check the resources you are about to use --and predicted costs, then create your cluster with

```
terraform apply terraform.tfplan
```
    

    