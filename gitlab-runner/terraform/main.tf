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

  provisioner "remote-exec" {
    # script = "${data.template_file.init.rendered}"
    inline = ["sudo gitlab-runner register --non-interactive --url ${var.gitlab_runner_url} --registration-token ${var.gitlab_runner_registration_token} --executor \"docker\" --docker-image alpine:latest --description \"docker-runner-${count.index}\" --tag-list \"docker,linux,ubuntu,xenial\" --run-untagged --locked=\"false\" "]
  }
}
