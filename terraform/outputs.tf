output "cachet-app-public-ipv4-address" {
  value = ["${digitalocean_droplet.cachet_app.ipv4_address}"]
}

output "cachet-app-public-ipv6-address" {
  value = ["${digitalocean_droplet.cachet_app.ipv6_address}"]
}
