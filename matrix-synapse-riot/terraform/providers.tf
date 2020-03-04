provider "digitalocean" {
  token = "${file(var.do_token)}"
}
provider "proxmox" {
  pm_tls_insecure = true
}
