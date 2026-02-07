terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~>2.32"
    }
  }
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}