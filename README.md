# Slurm Cluster on Google Cloud Platform


This is a quick guide to set up a GPU cluster on GCP. 

This cluster is relatively low-cost, and can be used to train models such as [Open Pretrained Transformers](https://github.com/mfmotta/open_pretrained_transformers) with number of parameters $N \propto 10^6$.


More details on training time and costs per epoch for values of $N$ to come.

[Here](https://github.com/mfmotta/slurm-gcp/tree/mm_branch/terraform/slurm_cluster/examples/slurm_cluster/cloud/full) you can find the configuration files used in this guide.

<br>

**Author:** Mariele Motta

<br>

## Requirements:
<br>

- a [Google Cloud Platform project](https://console.cloud.google.com/freetrial/)

- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/infrastructure-as-code) installed

<br>

For more details and a starting tutorial, please refer to [Build Infrastructure - Terraform GCP Example](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build).


<br>

## Setup

<br>

1 - Fork or clone [SchedMD/slurm-gcp](https://github.com/SchedMD/slurm-gcp).

2 - In [slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/cloud/full](https://github.com/SchedMD/slurm-gcp/tree/master/terraform/slurm_cluster/examples/slurm_cluster/cloud/full), edit the files ``example.tfvars``, ``variables.tf``, and ``main.tf``. 

Our setup creates a cluster with the following configuration (we only list some of the variables), see [example.tfvars](https://github.com/mfmotta/slurm-gcp/blob/mm_branch/terraform/slurm_cluster/examples/slurm_cluster/cloud/full/example.tfvars):

<br>

- **Login node:**

    disk_size_gb             = 16

    disk_type                = "pd-standard"

    machine_type             = "n1-standard-2"

    source_image             = "us-central1-docker.pkg.dev/your-project-id/your-repo/your-image:your-image-tag"

    Notice this considers you have uploaded an image to the repository ``your-repo`` in GCP's [Artifact Registry](https://cloud.google.com/artifact-registry/docs/docker/pushing-and-pulling). You can also use a base image from other registries, e.g. https://github.com/SchedMD/slurm-gcp/blob/master/docs/images.md.

<br>  

- **Controller node:**

    disk_size_gb           = 16

    disk_type              = "pd-standard"

    machine_type           = "n1-standard-4"

<br>

- **Partitions:**
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

This configuration has a single gpu per node and a maximum node count of two. We also use preemptible machines and a reduced SuspendTime to reduce costs.



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
    

    
