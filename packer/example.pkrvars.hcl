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

project_id = "hpc-gpus"
zone       = "us-central1-a"

access_token = "ya29.a0AWY7CknA-EvVe-O531kWCva1XgYvjhuBHS0dH2pTfqq4fta2OEQoaSgKtcQmg9DQsiFDGqHu9Fnd_zL-xvFcDBVoLhtLF_dh5wVoj4kEksVL59_ScJ-MUt32uocRNm0EFinrH6GtRY4ino5iNQgtxwU0IYUzaCgYKAZISARISFQG1tDrpl_0ThD04fH1dy5eFpbCXhQ0163"

# prefix = null

#########
# IMAGE #
#########

# NOTE: Your Project ID will be automatically appended
source_image_project_id = "ubuntu-os-cloud"

source_image        = "/var/lib/docker/overlay2"
source_image_family = "ubuntu-2004-lts"

# disk_type = "pd-standard"
# disk_size = 32
# machine_type = "n1-standard-16"

tags = [
  # "tag0",
  # "tag1",
]

# *NOT* intended for production use
# skip_create_image = true

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
