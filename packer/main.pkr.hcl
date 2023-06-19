# Copyright 2021 ${var.prefix} LLC
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

##########
# LOCALS #
##########

locals {
  slurm_version = regex("^(?P<major>\\d{2})\\.(?P<minor>\\d{2})(?P<end>\\.(?P<patch>\\d+)(?P<sub>-(?P<rev>\\d+\\w*))?|\\-(?P<meta>latest))$|^b:(?P<branch>.+)$", var.slurm_version)
  slurm_branch  = local.slurm_version["branch"] != null ? replace(local.slurm_version["branch"], ".", "-") : null
  slurm_semver  = join("-", compact([local.slurm_version["major"], local.slurm_version["minor"], local.slurm_version["patch"], local.slurm_branch]))

  ansible_dir = "../ansible"
  scripts_dir = "../scripts"

  ansible_vars = {
    slurm_version    = var.slurm_version
    install_cuda     = var.install_cuda
    nvidia_version   = var.nvidia_version
    nvidia_from_repo = var.nvidia_from_repo
    install_ompi     = var.install_ompi
    install_lustre   = var.install_lustre
    install_gcsfuse  = var.install_gcsfuse
  }

  parse_version = regex("^(?P<major>\\d+)(?:\\.(?P<minor>\\d+))?(?:\\.(?P<patch>\\d+))?|(?P<branch>\\w+)$", var.slurmgcp_version)
  branch        = local.parse_version["branch"] != null ? replace(local.parse_version["branch"], ".", "-") : null
  version       = join("-", compact([local.parse_version["major"], local.parse_version["minor"], local.parse_version["patch"], local.branch]))

  prefix_str  = try(length(var.prefix), 0) > 0 ? "${var.prefix}-" : ""
  root_str    = "slurm-gcp-${local.version}"
  variant_str = try(length(var.variant), 0) > 0 ? "-${var.variant}" : ""

  # If image_family_alt is set, use it instead of source_image_family
  #image_os_name    = try(length(var.image_family_alt), 0) > 0 ? var.image_family_alt : var.source_image_family
  #generated_family = "${local.prefix_str}${local.root_str}-${local.image_os_name}${local.variant_str}"

  # if image_family_name is set, use it for image_family instead of the generated one.
  #image_family = try(length(var.image_family_name), 0) > 0 ? var.image_family_name : local.generated_family
}

##########
# SOURCE #
##########

#A source block has two important labels: a builder type and a name. e.g. docker and ubuntu

source "docker" "my_source" {
  image  = var.docker_image
  commit = true
}


#########
# BUILD #
#########

build {
  ### general ###
  name = "my-build"

  #sources = ["sources.googlecompute.image"]
  sources = ["sources.docker.my_source"]
 

  ### post processor ###
  post-processor "manifest" {
    output = "manifest.json"

    strip_path = false
    strip_time = false
  }

  post-processor "shell-local" {
    inline = ["echo $PACKER_BUILD_NAME >> build.txt"]
  }

}


