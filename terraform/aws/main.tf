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

  backend "remote" {
    organization = "morriscloud"

    workspaces {
      name = "aws-terraform"
    }
  }
}

provider "aws" {
}

provider "cloudflare" {
}

locals {
  site_domain = "aws.terraform.static.morriscloud.com"
}

data "aws_iam_policy_document" "this" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

  }
}

resource "aws_s3_bucket" "this" {
  bucket        = local.site_domain
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.this.id
  key          = "index.html"
  source       = "index.html"
  etag         = filemd5("index.html")
  content_type = "text/html"
}

data "cloudflare_zone" "this" {
  name = "morriscloud.com"
}

resource "cloudflare_record" "this" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = local.site_domain
  value   = aws_s3_bucket.this.website_endpoint
  type    = "CNAME"
  ttl     = 1
  proxied = true
}
