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

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-07"
    Id      = "PublicReadBucketPolicy"
    Statement = [{
      Sid       = "IPAllow"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*"
      ]
      Condition = {
        NotIpAddress = {
          "aws:SourceIp" = "8.8.8.8/32"
        }
      }
    }]
  })
}

resource "aws_s3_bucket" "this" {
  bucket        = "aws.terraform.static.morriscloud.com"
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_s3_bucket_object" "index" {
  bucket = aws_s3_bucket.this.id
  key    = "index.html"
  source = "index.html"
  etag   = filemd5("index.html")
}

data "cloudflare_zone" "this" {
  name = "morriscloud.com"
}

resource "cloudflare_record" "this" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "aws.terraform.static"
  type    = "CNAME"
  value   = aws_s3_bucket.this.website_endpoint
  ttl     = 1
  proxied = true
}
