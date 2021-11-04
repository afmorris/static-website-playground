terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
}

provider "cloudflare" {
}

resource "aws_s3_bucket" "this" {
  bucket        = "aws.terraform.static.morriscloud.com"
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
  }
}

data "cloudflare_zone" "this" {
  name = "morriscloud.com"
}

resource "cloudflare_record" "this" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "aws.terraform.static"
  type    = "CNAME"
  value   = aws_s3_bucket.this.website_endpoint
}
