terraform {
  backend "gcs" {
    bucket = "ale-tf-state"
    prefix = "ncc-test-tf"
  }
}