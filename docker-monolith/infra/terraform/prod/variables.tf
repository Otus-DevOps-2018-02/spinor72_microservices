variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west4"
}

variable zone {
  description = "Zone"
  default     = "europe-west4-c"
}

variable machine_type {
  description = "Type of machine"
  default     = "n1-standard-1"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable docker_disk_image {
  description = "Disk image for docker app"
  default     = "ubuntu-1604-lts"
}

variable docker_count {
  description = "Number of docker hosts"
  default     = 1
}
