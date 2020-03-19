# Slurm on Google Cloud Platform

**NOTE: This will be the last release supporting Deployment Manager. Please
migrate your workflows to Terraform (found in the tf folder). All future
features / functionality will be integrated with Terraform.**

The following describes setting up a Slurm cluster using [Google Cloud
Platform](https://cloud.google.com), bursting out from an on-premise cluster to
nodes in Google Cloud Platform and setting a multi-cluster/federated setup with
a cluster that resides in Google Cloud Platform.

Also, checkout the [Slurm on GCP code lab](https://codelabs.developers.google.com/codelabs/hpc-slurm-on-gcp/).

The supplied scripts can be modified to work with your environment.

SchedMD provides professional services to help you get up and running in the
cloud environment. [SchedMD Commercial Support](https://www.schedmd.com/support.php)

Issues and/or enhancement requests can be submitted to
[SchedMD's Bugzilla](https://bugs.schedmd.com).

Also, join comunity discussions on either the
[Slurm User mailing list](https://slurm.schedmd.com/mail.html) or the
[Google Cloud & Slurm Community Discussion Group](https://groups.google.com/forum/#!forum/google-cloud-slurm-discuss).


# Contents

* [Stand-alone Cluster in Google Cloud Platform](#stand-alone-cluster-in-google-cloud-platform)
  * [Install using Deployment Manager](#install-using-deployment-manager)
  * [Install using Terraform (Beta)](#install-using-terraform-beta)
  * [Image-based Scaling](#image-based-scaling)
  * [Installing Custom Packages](#installing-custom-packages)
  * [Accessing Compute Nodes Directly](#accessing-compute-nodes-directly)
  * [OS Login](#os-login)
  * [Preemptible VMs](#preemptible-vms)
* [Hybrid Cluster for Bursting from On-Premise](#hybrid-cluster-for-bursting-from-on-premise)
  * [Node Addressing](#node-addressing)
  * [Configuration Steps](#configuration-steps)
* [Multi-Cluster / Federation](#multi-cluster-federation)
* [Troubleshooting](#troubleshooting)


## Stand-alone Cluster in Google Cloud Platform

The supplied scripts can be used to create a stand-alone cluster in Google Cloud
Platform. The scripts setup the following scenario:

* 1 - controller node
* N - login nodes
* Multiple partitions with their own machine type, gpu type/count, disk size,
  disk type, cpu platform, and maximum node count.


The default image for the instances is CentOS 7.

On the controller node, slurm is installed in:
/apps/slurm/<slurm_version>
with the symlink /apps/slurm/current pointing to /apps/slurm/<slurm_version>.

The login nodes mount /apps and /home from the controller node.


### Install using Deployment Manager

To deploy, you must have a GCP account and either have the
[GCP Cloud SDK](https://cloud.google.com/sdk/downloads)
installed on your computer or use the GCP
[Cloud Shell](https://cloud.google.com/shell/).

Steps:
1. Edit the `slurm-cluster.yaml` file and specify the required values

   **NOTE:** For a complete list of available options and their definitions,
   check out the [schema file](slurm.jinja.schema).

2. Spin up the cluster.

   Assuming that you have gcloud configured for your account, you can just run:

   ```
   $ gcloud deployment-manager deployments [--project=<project id>] create slurm --config slurm-cluster.yaml
   ```

3. Check the cluster status.

   You can see that status of the deployment by viewing:
   https://console.cloud.google.com/deployments

   and viewing the new instances:
   https://console.cloud.google.com/compute/instances

   To verify the deployment, ssh to the login node and run `sinfo` to see how
   many nodes have registered and are in an idle state.

   A message will be broadcast to the terminal when the installation is
   complete. If you log in before the installation is complete, you will either
   need to re-log in after the installation is complete or start a new shell
   (e.g. /bin/bash) to get the correct bash profile.

   ```
   $ gcloud compute [--project=<project id>] ssh [--zone=<zone>] g1-login0
   ...
   [bob@g1-login0 ~]$ sinfo
   PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
   debug*       up   infinite      8  idle~ g1-compute-0-[1-9]
   debug*       up   infinite      2   idle g1-compute-0-[0-1]
   ```

   **NOTE:** By default, Slurm will hide nodes that are in a power_save state --
   "cloud" nodes. The GCP Slurm scripts configure **PrivateData=cloud** in the
   slurm.conf so that the "cloud" nodes are always shown. This is done so that
   nodes that get marked down can be easily seen.

4. Submit jobs on the cluster.

   ```
   [bob@g1-login0 ~]$ sbatch -N2 --wrap="srun hostname"
   Submitted batch job 2
   [bob@g1-login0 ~]$ cat slurm-2.out
   g1-compute-0-0
   g1-compute-0-1
   ```

5. Tearing down the deployment.

   ```
   $ gcloud deployment-manager [--project=<project id>] deployments delete slurm
   ```

   **NOTE:** If additional resources (instances, networks) are created other
   than the ones created from the default deployment then they will need to be
   destroyed before deployment can be removed.

### Install using Terraform (Beta)

To deploy, you must have a GCP account and either have the
[GCP Cloud SDK](https://cloud.google.com/sdk/downloads) and
[Terraform](https://www.terraform.io/downloads.html)
installed on your computer or use the GCP
[Cloud Shell](https://cloud.google.com/shell/).

Steps:
1. cd to tf/examples/basic
2. Edit the `basic.tfvars` file and specify the required values
3. Deploy the cluster
   ```
   $ terraform init
   $ terraform apply -var-file=basic.tfvars
   ```
4. Tearing down the cluster

   ```
   $ terraform destroy -var-file=basic.tfvars
   ```

   **NOTE:** If additional resources (instances, networks) are created other
   than the ones created from the default deployment then they will need to be
   destroyed before deployment can be removed.

### Image-based Scaling
   The deployment will create a <cluster_name>-compute-\#-image instance, where
   \# is the index in the array of partitions, for each partition that is a base
   compute instance image. After installing necessary packages, the instance
   will be stopped and an image of the instance will be created. Subsequent
   bursted compute instances will use this image -- shortening the creation and
   boot time of new compute instances. While the compute image is running, the
   respective partitions will be marked as "down" to prevent jobs from
   launching until the image is created. After the image is created, the
   partition will be put into an "up" state and jobs can then run.

   **NOTE:** When creating a compute image that has gpus attached, the process
   can take about 10 minutes.

   If the compute image needs to be updated, it can be done with the following
   command:
   ```
   $ gcloud compute images create <cluster_name>-compute-#-image-$(date '+%Y-%m-%d-%H-%M-%S') \
                                  --source-disk <instance name> \
                                  --source-disk-zone <zone> --force \
                                  --family <cluster_name>-compute-#-image-family
   ```

   Existing images can be viewed on the console's [Images](https://console.cloud.google.com/compute/images)
   page.

### Installing Custom Packages
   There are two files, *custom-controller-install* and *custom-compute-install*, in
   the scripts directory that can be used to add custom installations for the
   given instance type. The files will be executed during startup of the
   instance types.

### Accessing Compute Nodes Directly

   There are multiple ways to connect to the compute nodes:
   1. If the compute nodes have external IPs you can connect directly to the
      compute nodes. From the [VM Instances](https://console.cloud.google.com/compute/instances)
      page, the SSH drop down next to the compute instances gives several
      options for connecting to the compute nodes.
   2. With IAP configured, you can SSH to the nodes regardless of external IPs or not.
      See https://cloud.google.com/iap/docs/enabling-compute-howto.
   3. Use Slurm to get an allocation on the nodes.
      ```
      $ srun --pty $SHELL
      [g1-login0 ~]$ srun --pty $SHELL
      [g1-compute-0-0 ~]$
      ```

### OS Login

   By default, all instances are configured with
   [OS Login](https://cloud.google.com/compute/docs/oslogin).

   > OS Login lets you use Compute Engine IAM roles to manage SSH access to
   > Linux instances and is an alternative to manually managing instance access
   > by adding and removing SSH keys in metadata.
   > https://cloud.google.com/compute/docs/instances/managing-instance-access

   This allows user uid and gids to be consistent across all instances.

   When sharing a cluster with non-admin users, the following IAM rules are
   recommended:

   1. Create a group for all users in admin.google.com.
   2. At the project level in IAM, grant the **Compute Viewer** and **Service
      Account User** roles to the group.
   3. At the instance level for each login node, grant the **Compute OS Login**
      role to the group.
      1. Make sure the **Info Panel** is shown on the right.
      2. On the compute instances page, select the boxes to the left of the
         login nodes.
      3. Click **Add Members** and add the **Compute OS Login** role to the group.
   4. At the organization level, grant the **Compute OS Login External User**
      role to the group if the users are not part of the organization.
   5. To allow ssh to login nodes without external IPs, configure IAP for the
      group.
      1. Go to the [Identity-Aware Proxy page](https://console.cloud.google.com/security/iap?_ga=2.207343252.68494128.1583777071-470618229.1575301916)
      2. Select project
      3. Click **SSH AND TCP RESOURCES** tab
      4. Select boxes for login nodes
      5. Add group as a member with the **IAP-secured Tunnel User** role
      6. Reference: https://cloud.google.com/iap/docs/enabling-compute-howto

   This allows users to access the cluster only through the login nodes.

### Preemptible VMs
   With preemptible_bursting on, when a node is found preempted, or stopped,
   the slurmsync script will mark the node as "down" and will attempt to
   restart the node. If there were any batch jobs on the preempted node, they
   will be requeued -- interactive (e.g. srun, salloc) jobs can't be requeued.

## Hybrid Cluster for Bursting from On-Premise

Bursting out from an on-premise cluster is done by configuring the
**ResumeProgram** and the **SuspendProgram** in the slurm.conf to 
*resume.py*, *suspend.py* in the scripts directory. *config.yaml* should
be configured so that the scripts can create and destroy compute instances in a
GCP project. 
See [Slurm Elastic Computing](https://slurm.schedmd.com/elastic_computing.html)
for more information.

Pre-reqs:
1. VPN between on-premise and GCP
2. bidirectional DNS between on-premise and GCP
3. Open ports to on-premise
   1. slurmctld
   2. slurmdbd
   3. SrunPortRange
4. Open ports in GCP for NFS from on-premise

### Node Addressing  
There are two options: 1) setup DNS between the on-premise network and the GCP
network or 2) configure Slurm to use NodeAddr to communicate with cloud compute
nodes. In the end, the slurmctld and any login nodes should be able to
communicate with cloud compute nodes, and the cloud compute nodes should be
able to communicate with the controller.

* Configure DNS peering  
   1. GCP instances need to be resolvable by name from the controller and any
      login nodes.
   2. The controller needs to be resolvable by name from GCP instances, or the
      controller ip address needs to be added to /etc/hosts.
   https://cloud.google.com/dns/zones/#peering-zones  

* Use IP addresses with NodeAddr
   1. disable cloud_dns in *slurm.conf*
   2. disable hierarchical communication in *slurm.conf*: `TreeWidth=65533`
   3. set `update_node_addrs` to `true` in *config.yaml*
   4. add controller's ip address to /etc/hosts on compute image

### Configuration Steps
1. Create a base instance

   Create a bare image and install and configure the packages (including Slurm)
   that you are used to for a Slurm compute node. Then create an image
   from it creating a family either in the form
   "<cluster_name>-compute-#-image-family" or in a name of your choosing.

2. Create a [service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts)
   and [service account key](https://cloud.google.com/docs/authentication/getting-started#creating_a_service_account)
   that will have access to create and delete instances in the remote project.

3. Install scripts

   Install the *resume.py*, *suspend.py*, *slurmsync.py* and
   *config.yaml.example* from the slurm-gcp repository's scripts directory to a
   location on the slurmctld. Rename *config.yaml.example* to *config.yaml* and
   modify the approriate values.  

   Add the path of the service account key to *google_app_cred_path* in *config.yaml*.
   
   Add the compute_image_family to each partition if different than the naming
   schema, "<cluster_name>-compute-#-image-family".


4. Modify slurm.conf:

   ```
   PrivateData=cloud
   
   SuspendProgram=/path/to/suspend.py
   ResumeProgram=/path/to/resume.py
   ResumeFailProgram=/path/to/suspend.py
   SuspendTimeout=600
   ResumeTimeout=600
   ResumeRate=0
   SuspendRate=0
   SuspendTime=300
   
   # Tell Slurm to not power off nodes. By default, it will want to power
   # everything off. SuspendExcParts will probably be the easiest one to use.
   #SuspendExcNodes=
   #SuspendExcParts=
   
   SchedulerParameters=salloc_wait_nodes
   SlurmctldParameters=cloud_dns,idle_on_node_suspend
   CommunicationParameters=NoAddrCache
   LaunchParameters=enable_nss_slurm
   
   SrunPortRange=60001-63000
   ```

5. Add a cronjob/crontab to call slurmsync.py to be called by SlurmUser.

   e.g.
   ```
   */1 * * * * /path/to/slurmsync.py
   ```

6. Test

   Try creating and deleting instances in GCP by calling the commands directly as SlurmUser.
   ```
   ./resume.py g1-compute-0-0
   ./suspend.py g1-compute-0-0
   ```

## Multi-Cluster / Federation
Slurm allows the use of a central SlurmDBD for multiple clusters. By doing
this, it also allows the clusters to be able to communicate with each other.
This is done by the client commands first checking with the SlurmDBD for the
requested cluster's IP address and port which the client then uses to
communicate directly with the cluster.

Some possible scenarios:
* An on-premise cluster and a cluster in GCP sharing a single SlurmDBD.
* An on-premise cluster and a cluster in GCP each with their own SlurmDBD but
  having each SlurmDBD know about each other using
  [AccountingStorageExternalHost](https://slurm.schedmd.com/slurm.conf.html#OPT_AccountingStorageExternalHost)
  in each slurm.conf.

The following considerations are needed for these scenarios:
* Regardless of location for the SlurmDBD, both clusters need to be able to
  talk to the each SlurmDBD and controller.
  * A VPN is recommended for traffic between on-premise and the cloud.
* In order for interactive jobs (srun, salloc) to work from the login nodes to
  each cluster, the compute nodes must be accessible from the login nodes on
  each cluster.
  * It may be easier to only support batch jobs between clusters.
    * Once a batch job is on a cluster, srun functions normally.
* If a firewall exists, srun communications most likely need to be allowed
  through it. Configure SrunPortRange to define a range for ports for srun
  communications.
* Consider how to present file systems and data movement between clusters.
* **NOTE:** All clusters attached to a single SlurmDBD must share the same user
  space (e.g. same uids across all the clusters).
* **NOTE:** Either all clusters and the SlurmDBD must share the same MUNGE key
  or use a separate MUNGE key for each cluster and another key for use between
  each cluster and the SlurmDBD. In order for cross-cluster interactive jobs to
  work, the clusters must share the same MUNGE key. See the following for more
  information:  
  [Multi-Cluster Operation](https://slurm.schedmd.com/multi_cluster.html)  
  [Accounting and Resource Limits](https://slurm.schedmd.com/accounting.html)


For more information see:  
[Multi-Cluster Operation](https://slurm.schedmd.com/multi_cluster.html)  
[Federated Scheduling Guide](https://slurm.schedmd.com/federation.html)



## Troubleshooting
1. Nodes aren't bursting?
   1. Check /var/log/slurm/resume.log for any errors
   2. Try creating nodes manually by calling resume.py manually **as the
      "slurm" user**.
      * **NOTE:** If you run resume.py manually with root, subsequent calls to
	resume.py by the "slurm" user may fail because resume.py's log file
	will be owned by root.
   3. Check the slurmctld logs
      * /var/log/slurm/slurmctld.log
      * Turn on the *PowerSave* debug flag to get more information.
        e.g.
        ```
        $ scontrol setdebugflags +powersave
        ...
        $ scontrol setdebugflags -powersave
        ```
2. Cluster environment not fully coming up  
   For example:
   * Slurm not being installed
   * Compute images never being stopped
   * etc.

   1. Check syslog (/var/log/messages) on instances for any errors. **HINT:**
      search for last mention of "startup-script."
3. General debugging
   * check logs
     * /var/log/messages
     * /var/log/slurm/*.log
     * **NOTE:** syslog and all Slurm logs can be viewed in [GCP Console's Logs Viewer](https://console.cloud.google.com/logs/viewer).
   * check GCP quotas
