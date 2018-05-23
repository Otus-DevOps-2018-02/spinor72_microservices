provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_instance" "gitlab-runner" {
  name         = "gitlab-runner-${count.index}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["gitlab-runner"]

  count = "${var.count}"

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  boot_disk {
    initialize_params {
      image = "${var.gitlab_runner_disk_image}"
      size  = "${var.gitlab_runner_disk_size}"
    }
  }

  network_interface {
    network = "default"

    access_config = {}
  }

  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  service_account {
    scopes = ["compute-rw", "storage-ro"]
  }

  provisioner "file" {
    content     = "{ \"insecure-registries\":[\"${var.gitlab_registry_address}:${var.gitlab_registry_port}\"] }"
    destination = "/tmp/daemon.json"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/daemon.json /etc/docker/daemon.json",
      "sudo systemctl restart docker",
      "sudo gitlab-runner register --non-interactive --url ${var.gitlab_runner_url} --registration-token ${var.gitlab_runner_registration_token} --executor \"docker\" --docker-image alpine:latest --description \"docker-runner-${count.index}\" --tag-list \"docker,linux,ubuntu,xenial\" --run-untagged --locked=\"false\" --docker-privileged ",
    ]
  }
}

resource "google_compute_instance" "gitlab-runner-machine" {
  name         = "gitlab-runner-machine"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["gitlab-runner"]

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  boot_disk {
    initialize_params {
      image = "${var.gitlab_runner_disk_image}"
      size  = "${var.gitlab_runner_disk_size}"
    }
  }

  network_interface {
    network = "default"

    access_config = {}
  }

  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  service_account {
    scopes = ["compute-rw", "storage-ro"]
  }

  provisioner "file" {
    content     = "{ \"insecure-registries\":[\"${var.gitlab_registry_address}:${var.gitlab_registry_port}\"] }"
    destination = "/tmp/daemon.json"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/daemon.json /etc/docker/daemon.json",
      "sudo systemctl restart docker",
      "sudo gitlab-runner register --non-interactive --url ${var.gitlab_runner_url} --registration-token ${var.gitlab_runner_registration_token} --executor \"shell\"  --description \"docker-runner-machine\" --tag-list \"linux,ubuntu,xenial,docker-machine\" --run-untagged --locked=\"false\"  ",
      "sudo adduser gitlab-runner docker",
    ]
  }
}
