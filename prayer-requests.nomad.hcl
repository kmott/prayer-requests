job "prayer-requests" {
  datacenters = ["klm"]
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "5m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }

  migrate {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "5m"
  }

  reschedule {
    delay          = "30s"
    delay_function = "fibonacci"
    max_delay      = "180s"
    unlimited      = true
  }

  group "prayer-requests" {
    restart {
      interval = "10m"
      attempts = 20
      delay    = "30s"
      mode     = "fail"
    }

    ephemeral_disk {
      size = 128
    }

    network {
      mode = "bridge"

      port "web" {
        to = 3000
      }
    }

    task "prayer-requests" {
      driver = "docker"

      config {
        image = "harbor.klmh.co/klm/prayer-requests:latest"
        ports = ["web"]
      }

      resources {
        cpu    = 100
        memory = 256
      }

      service {
        name = "prayer-requests"
        port = "web"
        tags = [
          "prayer-requests",
          "urlprefix-prayer-requests.klm.us-west.mywordpress.io/",
          "urlprefix-prayer-requests.klm.us-west.mywordpress.io:80/ redirect=301,https://prayer-requests.klm.us-west.mywordpress.io$path",
          "urlprefix-seekandpray.com/",
          "urlprefix-seekandpray.com:80/ redirect=301,https://seekandpray.com$path",
          "urlprefix-www.seekandpray.com/ redirect=301,https://seekandpray.com$path",
          "urlprefix-www.seekandpray.com:80/ redirect=301,https://seekandpray.com$path"
        ]

        check {
          name = "check_http"
          type = "http"
          port = "web"
          path = "/prayer-requests"
          interval = "5s"
          timeout = "2s"
        }
      }
    }
  }
}
