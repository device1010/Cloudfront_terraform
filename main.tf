terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# Crear bucket de S3 para el sitio web
resource "aws_s3_bucket" "website" {
  provider = aws.west
  bucket = "galia-website-bucke"
  //acl    = "public-read"

  website {
    index_document = "index.html"
  }
}

# Crear bucket de S3 para el contenido
resource "aws_s3_bucket" "content" {
  provider = aws.west
  bucket = "galia-content-bucke"
  //acl    = "public-read"
}

# Crear la distribución de CloudFront
resource "aws_cloudfront_distribution" "my_distribution" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_domain_name
    origin_id   = "${aws_s3_bucket.website.id}"

    custom_origin_config {
      http_port             = 80
      https_port            = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols  = ["TLSv1.2"]
    }
  }

  origin {
    domain_name = "${aws_s3_bucket.content.bucket_domain_name}"
    origin_id   = "${aws_s3_bucket.content.id}"

    custom_origin_config {
      http_port             = 80
      https_port            = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols  = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.website.id}"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  # Crear enlace para el sitio web
  ordered_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    path_pattern     = "/website/*"
    target_origin_id = "${aws_s3_bucket.website.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Crear enlace para el contenido
  ordered_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    path_pattern     = "/content/*"
    target_origin_id = "${aws_s3_bucket.content.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Configuración adicional
  comment         = "My CloudFront distribution"
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"
  viewer_certificate {
    //acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abcdef12-3456-7890-abcd-ef1234567890"
    //ssl_support_method  = "sni-only"
    cloudfront_default_certificate = true
  }
}
