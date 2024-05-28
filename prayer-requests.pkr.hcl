//
// Packer settings & plugins
//
packer {
  required_plugins {
    docker = {
      version = ">= 1.0"
      source = "github.com/hashicorp/docker"
    }
  }
}

//
// Variables
//
variable "base_image" {
  type    = string
  default = "harbor.klmh.co/klm/toolbox"
}

variable "base_image_version" {
  type    = string
  default = "12.4.2"
}

variable "app_name" {
  type    = string
  default = "prayer-requests"
}

variable "app_version" {
  type    = string
  default = "0.0.1"
}

variable "app_source_path" {
  type    = string
  default = "dist"
}

//
// The base image
//
source "docker" "container" {
  image  = "${var.base_image}:${var.base_image_version}"
  commit = true
  changes = [
    "ENTRYPOINT [\"node\", \"/var/www/html/express.js\"]",
  ]
}

//
// Base
//
build {
  name    = "container"
  sources = [
    "source.docker.container"
  ]

  provisioner "shell" {
    environment_vars = []
    inline_shebang = "/bin/bash -e"
    inline = [
      "pushd /tmp >/dev/null",

      "mkdir -p /var/www/html",

      "popd >/dev/null",
    ]
  }

  provisioner "file" {
    source = "${var.app_source_path}/"
    destination = "/var/www/html/"
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "harbor.klmh.co/klm/${var.app_name}"
      tags       = [
        "${var.app_version}-debian-${var.base_image_version}",
        "latest"
      ]
    }

    post-processor "docker-push" {
      login = false
    }
  }
}
