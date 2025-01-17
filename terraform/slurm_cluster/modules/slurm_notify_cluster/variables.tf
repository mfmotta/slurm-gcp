/**
 * Copyright (C) SchedMD LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "topic" {
  description = "Pubsub topic name or ID."
  type        = string
}

variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "The project_id must not be empty."
  }
}

variable "type" {
  description = "Notification type."
  type        = string
  default     = "reconfig"

  validation {
    condition     = contains(["reconfig", "restart", "devel"], lower(var.type))
    error_message = "Type can only be one of: reconfig; restart; devel."
  }
}

variable "triggers" {
  description = "Additional Terraform triggers."
  type        = map(string)
  default     = {}
}
