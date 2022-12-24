resource "google_network_services_edge_cache_origin" "instance" {
  name           = "media-cdn-origin"
  origin_address = "mediacdn.origin.example.net"
  description    = "The origin for Media CDN VOD Content"
  project      = <Enter your project number>
  protocol     = "HTTP2"
  port         = 443
  max_attempts = 3

  retry_conditions = [
    "CONNECT_FAILURE",
    "HTTP_5XX",
    "GATEWAY_ERROR",
    "RETRIABLE_4XX",
  ]

  timeout {
    connect_timeout      = "5s"
    max_attempts_timeout = "15s"
    response_timeout     = "30s"
    read_timeout         = "15s"
  }
}

resource "google_network_services_edge_cache_service" "instance" {
  name        = "media-cdn-vod"
  description = "Edge cache service for Media CDN vod delivery"
  project = <Enter your project number>
  # The following are ENABLED by default
  # disable_quic  = false
  # disable_http2 = false

  edge_ssl_certificates = ["projects/<your-project-ID>/locations/global/certificates/<you-cert-name>"]
  require_tls           = true


  edge_security_policy = "projects/<your-project-ID>/global/securityPolicies/<your-edge-policy-name>"

  routing {
    host_rule {
      description  = "host rule description"
      hosts        = ["example.video"]
      path_matcher = "routes"
    }

    path_matcher {
      name = "routes"
      route_rule {
        description = "All Main Content files"
        priority    = 100
        match_rule {
          prefix_match = "/"
        }
        origin = google_network_services_edge_cache_origin.instance.id
        route_action {
          url_rewrite {
            host_rewrite = "mediacdn.origin.example.net"
          }
          cdn_policy {
            cache_mode  = "FORCE_CACHE_ALL"
            client_ttl  = "86400s"
            default_ttl = "86400s"

            cache_key_policy {
              included_query_parameters = ["lastUpdatedAt"]
            }
            negative_caching = true
          }
          cors_policy {
            max_age           = "600s"
            allow_credentials = false
            allow_origins     = ["*"]
            allow_methods     = ["GET", "HEAD", "OPTIONS", "POST", "PUT"]
            allow_headers     = ["origin", "range", "pragma", "cache-control"]
          }
        }
        header_action {
          request_header_to_add {
            header_name  = "referer"
            header_value = "media:example"
          }
        }
      }
    }
  }

  log_config {
    enable      = true
    sample_rate = 0.5
  }
}
