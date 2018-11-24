# Digital Ocean Tag for all server instances
resource "digitalocean_tag" "matrix-home-service" {
  name = "matrix-homeserver"
}

# Domain name managed by Digital Ocean
#resource "digitalocean_domain" "matrix-home-service" {
#  name        = "${file(var.domain_name)}"
#  #ip_address  = "${digitalocean_droplet.matrix-server.ipv4_address}"
#  #ip6_address = "${digitalocean_droplet.matrix-server.ipv6_address}"
#}

# Matrix server Droplet
resource "digitalocean_droplet" "matrix-server" {
  image              = "debian-9-x64"
  name               = "matrix.${file(var.domain_name)}"
  region             = "tor1"
  size               = "1gb"
  tags               = ["${digitalocean_tag.matrix-home-service.id}"]
  private_networking = false
  ipv6               = true
  monitoring         = true
  ssh_keys           = ["${file(var.ssh_fingerprint)}"]
  connection {
    user             = "root"
    type             = "ssh"
    private_key      = "${file(var.pvt_key)}"
    timeout          = "2m"
  }
  provisioner "file" {
    source           = "matrix-server"
    destination      = "/tmp"
  }
  provisioner "remote-exec" {
    inline           = [
      "chmod +x /tmp/matrix-server/*.sh",
      "/tmp/matrix-server/bootstrap.sh ${file(var.domain_name)}",
    ]
  }
}

# DNS records for Matrix
resource "digitalocean_record" "matrix" {
  domain = "${file(var.domain_name)}"
  type   = "A"
  name   = "matrix"
  value  = "${digitalocean_droplet.matrix-server.ipv4_address}"
  ttl    = "86400"
}
resource "digitalocean_record" "matrix-v6" {
  domain = "${file(var.domain_name)}"
  type   = "AAAA"
  name   = "matrix"
  value  = "${digitalocean_droplet.matrix-server.ipv6_address}"
  ttl    = "86400"
}
resource "digitalocean_record" "matrix-caa" {
  domain = "${file(var.domain_name)}"
  type   = "CAA"
  name   = "matrix"
  flags  = 0
  tag  = "issue"
  value  = "letsencrypt.org."
  ttl    = "86400"
}

# DNS records for Riot Web frontend
resource "digitalocean_record" "chat" {
  domain = "${file(var.domain_name)}"
  type   = "A"
  name   = "chat"
  value  = "${digitalocean_droplet.matrix-server.ipv4_address}"
  ttl    = "86400"
}
resource "digitalocean_record" "chat-v6" {
  domain = "${file(var.domain_name)}"
  type   = "AAAA"
  name   = "chat"
  value  = "${digitalocean_droplet.matrix-server.ipv6_address}"
  ttl    = "86400"
}
resource "digitalocean_record" "chat-caa" {
  domain = "${file(var.domain_name)}"
  type   = "CAA"
  name   = "chat"
  flags  = 0
  tag    = "issue"
  value  = "letsencrypt.org."
  ttl    = "86400"
}

# Matrix SRV record
resource "digitalocean_record" "matrix-srv" {
  domain   = "${file(var.domain_name)}"
  type     = "SRV"
  name     = "_matrix._tcp"
  priority = "10"
  weight   = "0"
  port     = "8448"
  value    = "matrix.${file(var.domain_name)}."
  ttl      = "86400"
}

# Run after DNS records are configured
resource "null_resource" "matrix-server" {
  depends_on         = ["digitalocean_record.matrix"]
  connection {
    host             = "${digitalocean_droplet.matrix-server.ipv4_address}"
    user             = "root"
    type             = "ssh"
    private_key      = "${file(var.pvt_key)}"
    timeout          = "2m"
  }
  # Setup services such as NGINX, Let's Encrypt, Matrix, etc.
  provisioner "remote-exec" {
    inline           = [
      "/tmp/matrix-server/bootstrap-post-dns.sh ${file(var.domain_name)} ${file(var.do_token)}",
    ]
  }
}

# Setup CJDNS if selected
resource "null_resource" "matrix-server-cjdns" {
  count = "${var.cjdns != "0" ? 1 : 0}"
  depends_on         = ["null_resource.matrix-server"]
  connection {
    host             = "${digitalocean_droplet.matrix-server.ipv4_address}"
    user             = "root"
    type             = "ssh"
    private_key      = "${file(var.pvt_key)}"
    timeout          = "2m"
  }
  # Setup CJDNS
  provisioner "remote-exec" {
    inline           = [
      "/tmp/matrix-server/bootstrap-cjdns.sh ${file(var.domain_name)}",
    ]
  }
  # Get the CJDNS IPv6
  provisioner "local-exec" {
    command          = "scp -B -o 'StrictHostKeyChecking no' -o UserKnownHostsFile=/dev/null -i ${var.pvt_key} root@${digitalocean_droplet.matrix-server.ipv4_address}:/tmp/matrix-server/ipv6-cjdns .keys/ipv6-cjdns"
  }
}

# Create DNS record for Chat CJDNS
resource "digitalocean_record" "chat-cjdns" {
  depends_on = ["null_resource.matrix-server-cjdns", "null_resource.matrix-server"]
  count      = "${var.cjdns != "0" ? 1 : 0}"
  domain     = "${file(var.domain_name)}"
  type       = "AAAA"
  name       = "h.chat"
  value      = "${file(".keys/ipv6-cjdns")}"
  ttl        = "86400"
}

resource "digitalocean_record" "chat-cjdns-caa" {
  depends_on = ["null_resource.matrix-server-cjdns", "null_resource.matrix-server"]
  count      = "${var.cjdns != "0" ? 1 : 0}"
  domain     = "${file(var.domain_name)}"
  type       = "CAA"
  name       = "h.chat"
  flags      = 0
  tag        = "issue"
  value      = "letsencrypt.org."
  ttl        = "86400"
}

# Create DNS records for Matrix CJDNS
resource "digitalocean_record" "matrix-cjdns" {
  depends_on = ["null_resource.matrix-server-cjdns", "null_resource.matrix-server"]
  count      = "${var.cjdns != "0" ? 1 : 0}"
  domain     = "${file(var.domain_name)}"
  type       = "AAAA"
  name       = "h.matrix"
  value      = "${file(".keys/ipv6-cjdns")}"
  ttl        = "86400"
}

resource "digitalocean_record" "matrix-cjdns-caa" {
  depends_on = ["null_resource.matrix-server-cjdns", "null_resource.matrix-server"]
  count      = "${var.cjdns != "0" ? 1 : 0}"
  domain     = "${file(var.domain_name)}"
  type       = "CAA"
  name       = "h.matrix"
  flags      = 0
  tag        = "issue"
  value      = "letsencrypt.org."
  ttl        = "86400"
}

# Get cert from Let's Encrypt
resource "null_resource" "matrix-server-dehydrated" {
  depends_on         = ["null_resource.matrix-server-cjdns", "null_resource.matrix-server"]
  connection {
    host             = "${digitalocean_droplet.matrix-server.ipv4_address}"
    user             = "root"
    type             = "ssh"
    private_key      = "${file(var.pvt_key)}"
    timeout          = "2m"
  }
  # Get an valid SSL Cert from Let's Encrypt
  provisioner "remote-exec" {
    inline           = [
      "/tmp/matrix-server/bootstrap-dehydrated.sh",
    ]
  }
}

# Run cleanup after null_resource matrix-server-dehydrated is done
resource "null_resource" "matrix-server-cleanup" {
  depends_on         = ["null_resource.matrix-server-dehydrated", "null_resource.matrix-server"]
  connection {
    host             = "${digitalocean_droplet.matrix-server.ipv4_address}"
    user             = "root"
    type             = "ssh"
    private_key      = "${file(var.pvt_key)}"
    timeout          = "2m"
  }
  # Get the password for sysadmin user
  provisioner "local-exec" {
    command          = "scp -B -o 'StrictHostKeyChecking no' -o UserKnownHostsFile=/dev/null -i ${var.pvt_key} root@${digitalocean_droplet.matrix-server.ipv4_address}:/tmp/matrix-server/passwd-sysadmin .keys/passwd-sysadmin"
  }
  # Clean up
  provisioner "remote-exec" {
    inline           = [
      "/tmp/matrix-server/bootstrap-cleanup.sh",
    ]
  }
  # Reboot
  provisioner "local-exec" {
    command          = "ssh -o 'StrictHostKeyChecking no' -o UserKnownHostsFile=/dev/null -i ${var.pvt_key} root@${digitalocean_droplet.matrix-server.ipv4_address} '(sleep 2; reboot)&'"
  }
}


# Print summary
output "digital_ocean_droplets" {
  depends_on = ["digitalocean_record.*"]
  value      = [
    "${digitalocean_droplet.matrix-server.name}:             ${digitalocean_droplet.matrix-server.status}",
  ]
}

output "ssh_access" {
  depends_on = ["null_resource.matrix-server-cleanup"]
  value      = [
    "matrix:   ssh -i .keys/id_rsa sysadmin@${digitalocean_record.matrix.fqdn}",
    "passwd:   ${file(".keys/passwd-sysadmin")}",
  ]
}
