terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "2.5.0"
    }
  }
}

provider "lxd" {
}

variable "ssh_pub_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

resource "lxd_project" "knfs" {
  name        = "ldap-krb5-nfs"
  description = "LDAP, Kerberos5 and NFS PoC"
  config = {
    "features.storage.volumes" = true
    "features.images"          = false
    "features.networks"        = false
    "features.profiles"        = true
    "features.storage.buckets" = true
  }
}

resource "lxd_network" "knfs" {
  name = "ldap-krb5-nfs"

  config = {
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
    "dns.domain"   = "knfs.local"
  }
}

resource "lxd_storage_pool" "knfs" {
  project = lxd_project.knfs.name
  name    = "ldap-krb5-nfs"
  driver  = "dir"
}

resource "lxd_profile" "knfs" {
  project = lxd_project.knfs.name
  name    = "ldap-krb5-nfs"

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = lxd_network.knfs.name
    }
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = lxd_storage_pool.knfs.name
      path = "/"
    }
  }

  config = {
    "cloud-init.user-data" : templatefile("cloud-init.yaml.tftpl", { ssh_pub = file(var.ssh_pub_path) })
  }
}

resource "lxd_instance" "krb5" {
  project  = lxd_project.knfs.name
  name     = "krb5"
  image    = "ubuntu:24.04"
  type     = "virtual-machine"
  profiles = [lxd_profile.knfs.name]
}

resource "lxd_instance" "nfs" {
  project  = lxd_project.knfs.name
  name     = "nfs"
  image    = "ubuntu:24.04"
  type     = "virtual-machine"
  profiles = [lxd_profile.knfs.name]
}

resource "lxd_instance" "client" {
  project  = lxd_project.knfs.name
  name     = "client"
  image    = "ubuntu:24.04"
  type     = "virtual-machine"
  profiles = [lxd_profile.knfs.name]
}
