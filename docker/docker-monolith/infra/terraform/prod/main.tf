provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_instance" "docker" {
  count        = "${var.docker_count}"
  name         = "docker-app-${count.index}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["reddit-app", "docker-host"]

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "${var.docker_disk_image}"
    }
  }

  # определение сетевого интерфейса
  network_interface {
    network = "default"

    access_config = {}
  }
}

module "docker_host" {
  source = "../modules/ansible"
  name   = ""
  host   = ""
  hosts  = "${google_compute_instance.docker.*.network_interface.0.access_config.0.assigned_nat_ip}"
  names  = "${google_compute_instance.docker.*.name}"
  groups = ["app"]

  vars = {}
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default"

  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["reddit-app"]
}
