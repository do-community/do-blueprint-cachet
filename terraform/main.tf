provider "digitalocean" {
  token = "${var.do_token}"
}

# Blueprint tags

resource "digitalocean_tag" "bp" {
  name = "bp"
}

resource "digitalocean_tag" "bp_cachet" {
  name = "bp-cachet"
}

resource "digitalocean_tag" "bp_cachet_app" {
  name = "bp-cachet-app"
}

resource "digitalocean_tag" "bp_cachet_db" {
  name = "bp-cachet-db"
}

# Droplet resources

resource "digitalocean_droplet" "cachet_app" {
  name       = "cachet-app"
  image      = "ubuntu-16-04-x64"
  region     = "nyc3"
  size       = "s-1vcpu-1gb"
  ssh_keys   = ["${var.ssh_keys}"]
  ipv6       = true
  monitoring = true
  user_data  = "${file("${path.module}/files/userdata")}"
  private_networking = true
  tags = [
    "${digitalocean_tag.bp.id}",
    "${digitalocean_tag.bp_cachet.id}",
    "${digitalocean_tag.bp_cachet_app.id}"
  ]
}

resource "digitalocean_droplet" "cachet_db" {
  name       = "cachet-db"
  image      = "ubuntu-16-04-x64"
  region     = "nyc3"
  size       = "s-1vcpu-1gb"
  ssh_keys   = ["${var.ssh_keys}"]
  monitoring = true
  user_data  = "${file("${path.module}/files/userdata")}"
  private_networking = true
  tags = [
    "${digitalocean_tag.bp.id}",
    "${digitalocean_tag.bp_cachet.id}",
    "${digitalocean_tag.bp_cachet_db.id}"
  ]
}

# Cloud Firewall resources

resource "digitalocean_firewall" "management" {
  name = "bp-cachet-management"

  tags = ["${digitalocean_tag.bp_cachet_app.id}", "${digitalocean_tag.bp_cachet_db.id}"]

  inbound_rule = [
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
  ]

  outbound_rule = [
    {
      protocol              = "tcp"
      port_range            = "all"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "udp"
      port_range            = "all"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
  ]
}

resource "digitalocean_firewall" "web" {
  name = "bp-cachet-web"

  tags = ["${digitalocean_tag.bp_cachet_app.id}"]

  inbound_rule = [
    {
      protocol         = "tcp"
      port_range       = "80"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "443"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
  ]
}

resource "digitalocean_firewall" "mysql" {
  name = "bp-cachet-mysql"

  tags = ["${digitalocean_tag.bp_cachet_db.id}"]

  inbound_rule = [
    {
      protocol         = "tcp"
      port_range       = "3306"
      source_tags = ["${digitalocean_tag.bp_cachet_app.id}"]
    },
  ]
}

# Resources for the Ansible dynamic inventory script

resource "ansible_host" "ansible_cachet_app" {
  inventory_hostname = "${digitalocean_droplet.cachet_app.name}"
  groups             = ["cachet"]

  vars {
    ansible_host = "${digitalocean_droplet.cachet_app.ipv4_address}"
  }
}

resource "ansible_host" "ansible_mysql_node" {
  inventory_hostname = "${digitalocean_droplet.cachet_db.name}"
  groups             = ["mysql"]

  vars {
    ansible_host = "${digitalocean_droplet.cachet_db.ipv4_address}"
  }
}
