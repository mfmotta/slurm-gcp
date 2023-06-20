# Copyright (C) SchedMD LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###########
# GENERAL #
###########

project_id = "your-project-id"
zone       = "your-project-zone"

# prefix = null

#########
# IMAGE #
#########

# your local docker image:tag, e.g.:
docker_image = "nvidia/cuda:11.6.0-devel-ubuntu20.04"


tags = [
  # "tag0",
  # "tag1",
]


#############
# PROVISION #
#############

slurm_version = "22.05.9"

# Disable some ansible roles here; they are enabled by default
# install_cuda = false
# install_ompi = false
# install_lustre = false
# install_gcsfuse = false

### Service Account ###

service_account_email = "default"

service_account_scopes = [
  "https://www.googleapis.com/auth/cloud-platform",
  "https://www.googleapis.com/auth/artifactregistry.readonly"
 ]

###########
# NETWORK #
###########

# network_project_id = "<NETWORK_PROJECT_ID>"
# subnetwork = "<SUBNETWORK_ID>"

# add extra verbosity arguments to ensure stdout/stderr appear in output
extra_ansible_provisioners = [
  #  {
  #    playbook_file = "/home/user/playbooks/custom.yaml"
  #    galaxy_file = null
  #    extra_arguments = ["-vv"]
  #    user = null
  #  },
]

# More options are listed in the variables.pkr.hcl
