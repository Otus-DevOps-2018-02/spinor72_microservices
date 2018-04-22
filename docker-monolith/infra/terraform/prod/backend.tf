terraform {
  backend "gcs" {
    bucket = "storage-bucket-spinor72-test"
    prefix = "terraform/docker"
  }
}
