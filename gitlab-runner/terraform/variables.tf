variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west4"
}

variable zone {
  description = "Zone"
  default     = "europe-west4-b"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable count {
  description = "Number of instances"
  default     = 2
}

variable gitlab_runner_disk_image {
  description = "Disk image for gitlab runner"
  default     = "gitlab-runner-base"
}

variable gitlab_runner_disk_size {
  description = "Disk size for gitlab runner"
  default     = "100"
}

variable gitlab_runner_url {
  description = "Url for Gitlab"
}

variable gitlab_runner_registration_token {
  description = "Runner token"
}

variable machine_type {
  description = "Machine type"
  default     = "n1-standard-1"
}
