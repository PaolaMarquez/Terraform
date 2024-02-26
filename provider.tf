variable "ssh_fingerprint" {}
variable "pvt_key" {}
variable "pub_key" {}
variable "do_token" {}
variable "region" {}
variable "name_project" {}
variable "size" {} 

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "terraform" {
  name = "prueba"
}