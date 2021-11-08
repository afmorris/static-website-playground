terraform {
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 4.51.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }

  backend "remote" {
    organization = "morriscloud"

    workspaces {
      name = "static-website-playground-oci-terraform"
    }
  }
}

provider "oci" {
}

provider "cloudflare" {
}

locals {
  site_domain = "oci-terraform-static.morriscloud.com"
}

# resource "oci_objectstorage_bucket" "this" {
#   compartment_id = ""
#   namespace = ""
#   name = local.site_domain
#   access_type = "ObjectReadWithoutList"
# }

# resource "oci_objectstorage_object" "this" {

# }

data "cloudflare_zone" "this" {
  name = "morriscloud.com"
}

resource "cloudflare_record" "this" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = local.site_domain
  value   = ""
  type    = "CNAME"
  ttl     = 1
  proxied = true
}
