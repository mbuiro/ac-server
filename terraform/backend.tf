terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "btech"

    workspaces {
      name = "tf-acserver-01"
    }
  }
}