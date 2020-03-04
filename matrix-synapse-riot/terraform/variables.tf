variable "domain_name" {
  default = ".keys/domain_name"
}
variable "do_token" {
  default = ".keys/do_token"
}
variable "pub_key" {
  default = ".keys/id_rsa.pub"
}
variable "pvt_key" {
  default = ".keys/id_rsa"
}
variable "ssh_fingerprint" {
  default = ".keys/ssh_fingerprint"
}
variable "nameserver" {
  default = ".keys/nameserver"
}
variable "interface_gw" {
  default = ".keys/interface_gw"
}
variable "interface_ip" {
  default = ".keys/interface_ip"
}
variable "interface_ip_netmask" {
  default = ".keys/interface_ip_netmask"
}
variable "interface_gw6" {
  default = ".keys/interface_gw6"
}
variable "interface_ip6" {
  default = ".keys/interface_ip6"
}
variable "interface_ip6_netmask" {
  default = ".keys/interface_ip6_netmask"
}
variable "cjdns" {
  description = "Set up Matrix and Riot on cjdns"
  default = true
}
variable "yggdrasil" {
  description = "Set up Matrix and Riot on Yggdrasil"
  default = true
}
