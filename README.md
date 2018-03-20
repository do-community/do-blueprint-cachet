## Cachet Open Source Status Page w/ Let's Encrypt and a MySQL Database

Welcome to the Cachet Blueprint repository. This repository can be used to quickly set up a status page for your application or business using [Cachet](https://cachethq.io/), an open source status page app written in [PHP](http://www.php.net/) using the [Laravel](https://laravel.com/) framework.

This process should take roughly thirty minutes.

By default, after cloning this project and executing the [Terraform](https://www.terraform.io/) and [Ansible](https://www.ansible.com/) steps described below, you will have an Ubuntu 16.04 database server running MySQL, connected to an Ubuntu 16.04 application server running the Cachet app with Nginx and PHP-FPM. The two servers will communicate over DigitalOcean's private network, with Cloud Firewalls set up to restrict access where appropriate. Nginx will be configured with SSL/TLS certificates using the [Let's Encrypt](https://letsencrypt.org/) certificate authority.

Additionally, local backups will be enabled using [`laravel-backup`](https://github.com/spatie/laravel-backup), with optional support for exporting backups to DigitalOcean's [Spaces](https://www.digitalocean.com/products/spaces/) object storage service.

## Architecture

> **Note:** architecture diagram coming soon

* 1 Cachet App Droplet

  * Specs: 1 VCPU, 1GB memory, 25GB SSD
  * Datacenter: NYC3
  * OS: Ubuntu 16.04
  * Software: Nginx, PHP-FPM, Certbot

* 1 MySQL Database Droplet

  * Specs: 1 VCPU, 1GB memory, and 25GB SSD
  * Datacenter: NYC3
  * OS: Ubuntu 16.04
  * Software: MySQL

* 1 Spaces Bucket (optional, but off-server backups are highly recommended)

Using the given Droplet sizes, and one Spaces bucket, **this infrastructure will cost $15 a month** to run.

## Quickstart

Here are the steps to get up and running.

### Requirements

The software required to run DigitalOcean Blueprints is provided within a Docker image. You will need to install Docker locally to run these playbooks. You can find up-to-date instructions on how to download and install Docker on your computer [on the Docker website](https://www.docker.com/community-edition#/download).

If you'd prefer not to install Docker locally, you can create a dedicated control Droplet using the [DigitalOcean Docker One-click application](https://www.digitalocean.com/products/one-click-apps/docker/) instead. You will also need [Git](https://git-scm.com/downloads) installed.

### Clone the Repo

To get started, clone this repository into a writeable directory on your Docker-enabled machine:

```shell
cd ~
git clone https://github.com/do-community/do-blueprint-cachet
```

### Add a Bash Alias for the Infrastructure Tools Docker Container

Open your shell configuration file using your preferred text editor:

```shell
nano ~/.bashrc
```

Scroll to the bottom of the file and add the following `bp()` function and `complete` definition line:

```shell
function bp() {
    docker run -it --rm \
    -v "${PWD}":"/blueprint" \
    -v "${HOME}/.terraform.d":"/root/.terraform.d" \
    -v "${HOME}/.ssh":"/root/.ssh" \
    -v "${HOME}/.config":"/root/.config" \
    -e ANSIBLE_TF_DIR='./terraform' \
    -e HOST_HOSTNAME="${HOSTNAME}" \
    docommunity/bp "$@"
}

complete -W "terraform doctl ./terraform.py ansible ansible-connection ansible-doc ansible-inventory ansible-pull ansible-config ansible-console ansible-galaxy ansible-playbook ansible-vault" "bp"
```

These additions will simplify a long and complicated Docker-based command line down to a simple `bp`.

Save and close the file when you are finished. Source the file to load the new function into your current session:

```
source ~/.bashrc
```

Run the Terraform command, prefixed by `bp`, to test the setup:

```
bp terraform -v
```

Terraform should output its version number. You are now ready to run the setup playbook.

### Run the `setup.yml` Local Playbook

Next, enter the directory created by `git clone`, and run the `setup.yml` playbook. This will configure the local repository and credentials.

> **Note:** The initial run of this playbook may show some warnings since the Ansible dynamic inventory script cannot yet find a valid state file from Terraform. This is expected and the warnings will not be present once a Terraform state file is created.

```
cd do-blueprint-cachet
bp ansible-playbook setup.yml
```

Enter your DigitalOcean read/write API key if prompted (you can generate a read/write API key by visiting the [API section of the DigitalOcean Control Panel](https://cloud.digitalocean.com/settings/api/tokens) and clicking "Generate New Token"). Confirm the operation to create a dedicated SSH key pair by typing "yes" when prompted. As part of this configuration, a dedicated SSH key pair will be generated and added to your DigitalOcean account for managing Blueprints infrastructure.

The playbook will:

* Check the `doctl` configuration to try to find an existing DigitalOcean API key
* Prompt you to enter an API key if it could not find one in the `doctl` configuration
* Check if a dedicated `~/.ssh/blueprint-id_rsa` SSH key pair is already available locally.
* Generate the `~/.ssh/blueprint-id_rsa` key pair if required and add it to your DigitalOcean account.
* Install the Terraform Ansible provider and the associated Ansible dynamic inventory script that allows Ansible to read from the Terraform state file
* Generate a `terraform/terraform.tfvars` file with your DigitalOcean API key and SSH key defined
* Initialize the `terraform` directory so that it's ready to use.
* Install the Ansible roles needed to run the main playbook.

With setup complete, we can create our actual Droplets, tags, and firewalls next.

### Create the Infrastructure

Move into the `terraform` directory. Adjust the `terraform.tfvars` and `main.tf` file if necessary. This is when you would adjust the choice of datacenter or the size of your Droplets, for instance (See **Customizing this Blueprint** at the end of this document for details).

When you are ready, create your infrastructure with `terraform apply`:

```shell
cd terraform
bp terraform apply
```

Terraform will output a list of actions it will take to create your infrastructure.

Type `yes`, then hit `ENTER` to confirm the operation.

Terraform will create the necessary Droplets, tags, and firewalls. When finished it will output some status information, along with information about the IP addresses of our Cachet app server:

```
Apply complete! Resources: 11 added, 0 changed, 0 destroyed.

Outputs:

cachet-app-public-ipv4-address = [
    203.0.113.11
]
cachet-app-public-ipv6-address = [
    2001:0DB8:0800:00a1:0000:0000:1456:e001
]
```

Note both addresses. We will set up DNS entries for them next.

### Create DNS Records

Before configuring the servers, you will need to create DNS records to point a domain name to the Cachet server. Throughout this Blueprint we will use the example domain of `status.example.com`.

The exact procedure to set up the correct DNS records will vary depending on your DNS provider. You'll need to create an `A` record pointing to the IPv4 address that was output in the previous step. Additionally, you should create an `AAAA` record for the IPv6 address.

If you are using DigitalOcean as your DNS provider, instructions for how to create these records can be found in our tutorial [How To Set Up a Host Name with DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-host-name-with-digitalocean). If you are using a different DNS service provider, please refer to their documentation for more information.

> **Note:** It is possible to create DNS records using Terraform. However, in this case it is probably simpler/safer to do so manually. You can find more information about managing DNS records with Terraform at [the documentation for DigitalOcean's `record` resource](https://www.terraform.io/docs/providers/do/r/record.html) or [this list of Terraform-enabled DNS providers](https://www.terraform.io/docs/providers/type/network-index.html).

We must set up these DNS records before running the Ansible configuration step, because Let's Encrypt needs to verify that the Cachet server is responding at `status.example.com` before it will issue an SSL/TLS certificate.

### Test Connectivity

Move back up to the main repository directory. Use the `ansible -m ping` command to check whether the hosts are accessible yet:

```shell
bp ansible -m ping all
```

This command will return failures if the servers are not yet accepting SSH connections or if the userdata script that installs Python has not yet completed. Run the command again until these failures disappear from all hosts.

### Set Configuration Variables

This Blueprint has some configuration variables that need to be set before it will install and function properly. Mostly these have to do with setting up Cachet to use external mail and object storage services.

All of the variables we need to configure reside in the `group_vars` directory. This directory is split into subfolders for each Ansible host group: `all` for variables shared between all hosts, `cachet` for the Cachet host, and `mysql` for the database host.

In these directories you will see `vars.yml` files, and `vault.yml` files. `vars.yml` is for non-sensitive information, and `vault.yml` is where we put our secrets (passwords and tokens) and encrypt them. This is so we don't accidentally leak secrets to the public when using version control.

Here is an overview of the directory, with some annotations after the files that need updating:

```shell
group_vars/
├── all
│   ├── vars.yml
│   └── vault.yml # database passwords
├── cachet
│   ├── vars.yml  # general Cachet app configuration
│   └── vault.yml # app key, mail and object storage passwords
└── mysql
    └── vars.yml
```

The files all contain comments with details and example values for each variable. Work your way through the three files that need updating, filling out all necessary information. There should be no blank values when you're done, except for possibly the four `cachet_spaces_` variables — if you choose not to export your backups to Spaces — and the `cachet_mail_host` and `cachet_mail_port` variables if you're using a transactional mail service, as seen below.

#### Example Mail Driver Configurations

Cachet uses a mail service to send out verification emails to your users, as well as status updates to those who've signed up to be emailed when updates are posted. The mail driver can be configured to use SMTP servers, transactional email services, or even a local log file. Two example configurations are shown below. For more detailed help please look at [the official Cachet mail configuration docs](https://docs.cachethq.io/docs/configuring-mail).

An SMTP-based configuration using Gmail (for example) would look like the following (this works for both regular Gmail and corporate Gsuite accounts):

```yaml
cachet_mail_driver: smtp
cachet_mail_host: smtp.gmail.com
cachet_mail_port: 587
cachet_mail_username: username@example.com
cachet_mail_password: "{{ vault_cachet_mail_password }}"
cachet_mail_from_address: username@example.com
cachet_mail_from_name: "Example Status"
cachet_mail_encryption: tls
```

Be sure to add your password to the `vault_cachet_mail_password` variable in `group_vars/cachet/vault.yml` as well. If you use two-factor authentication with Gmail or Gsuite, you'll need to make an "App password" for this purpose. You can do so [here](https://security.google.com/settings/security/apppasswords).

Here is a setup that uses the [Mailgun](https://www.mailgun.com/) transactional email service:

```yaml
cachet_mail_driver: mailgun
cachet_mail_host:
cachet_mail_port:
cachet_mail_username: mail.example.com
cachet_mail_password: "{{ vault_cachet_mail_password }}"
cachet_mail_from_address: status@example.com
cachet_mail_from_name: "Example Status"
cachet_mail_encryption: tls
```

Again, be sure to edit the `vault_cachet_mail_password` variable in `group_vars/cachet/vault.yml` as well. For Mailgun this will be an API token.

#### Encrypting the Vault Files

When all of your configuration is filled out, encrypt your vault files using `ansible-vault`:

```shell
bp ansible-vault encrypt group_vars/*/vault.yml
```

You will be prompted twice for a password. Enter a strong password.

> **Note:** For more information on using Ansible Vault files, take a look at [the official Ansible Vault documentation](http://docs.ansible.com/ansible/latest/playbooks_vault.html). Many text editors have plugin support for vault files, so you can easily decrypt, edit then re-encrypt the files. You can also run `bp ansible-vault decrypt group_vars/*/vault.yml` to decrypt your vault files at any time.

#### Running the Playbook

We are now ready to run the main Ansible Playbook. We will use the `ansible-playbook` command:

```shell
bp ansible-playbook site.yml --ask-vault-pass
```

You will be prompted for your Vault password. After you enter it, Ansible will connect to the hosts and run the required tasks to set up the infrastructure.

### Finishing the Deployment

After the Droplets are set up, you'll still need to walk through Cachet's web-based setup. It's a short, three-step process where you'll choose some additional settings and set up a user account.

> **Important: Step 1 will ask you for some cache and mail driver information, _despite the fact that we've already configured this_**.

> Whatever you enter here will overwrite the configuration that Ansible just generated. Leave the **Cache Driver** and **Session Driver** settings as is (`APC(u)`), and fill in the mail settings with the same values entered in the previous step.

The following steps will prompt you for new information about time zones and language choices, then set up the first user. When done, you'll be taken to the Cachet dashboard. Your installation is finished!

### Testing and Operating the Deployment

Once the infrastructure is configured, you can SSH into the Cachet server to check the setup. SSH into the host from the same computer as your Blueprint repository (this machine will have the correct SSH credentials):

```shell
ssh -i ~/.ssh/blueprint-id_rsa root@your-cachet-droplet-ip-or-domain
```

Though any configuration changes should be done through Ansible, there are a few Laravel commands you might want to run on the server to operate your installation. First change to the Cachet directory:

```shell
cd /var/www/cachet
```

If you're just trying out Cachet and want to load some sample data in the interface, you can use the following command to seed the database with demo data:

```shell
php artisan cachet:seed
```

To manually run a backup, enter the following:

```shell
php artisan backup:run
```

You can also list out your backups and their status with:

```shell
php artisan backup:list
```

### Deprovisioning the Infrastructure

To destroy all of the servers in this Blueprint, move into the `terraform` directory again and use the `destroy` action:

```shell
cd terraform
bp terraform destroy
```

You will be prompted to confirm the action. While you can easily spin up the infrastructure again using the Terraform and Ansible steps, keep in mind that any data you added will be lost when your Droplets are destroyed.

## Ansible Roles

This repository uses the following role to configure the MySQL database server:

* [MySQL role](https://github.com/geerlingguy/ansible-role-mysql)

You can read the README file associated with this role to understand how to adjust the configuration further.

## Customizing this Blueprint

You can customize this Blueprint in a number of ways depending on your needs.

### Modifying Infrastructure Scale

This infrastructure is designed to scale vertically. That is, if you need to serve more simultaneous users, you should choose a larger, more performant Droplet. As Cachet is not a database-heavy application, most of your compute power should be put into the application server.

> **Note:** Adjusting the scale will affect the cost of your deployment.

To adjust the scale of your infrastructure, open the `terraform/main.tf` file in a text editor:

```shell
nano terraform/main.tf
```

You can change the `size` property of the `cachet_app` resource:

```terraform
resource "digitalocean_droplet" "cachet_app" {
  . . .
  size       = "s-1vcpu-1gb"
  . . .
```

To retrieve a list of possible Droplet sizes, use the `bp doctl compute size list` command.

> **Note:** If you update this property and rerun `bp terraform apply` on a live site, there will be some downtime as the Droplet is resized.

### Restricting Management Firewall Rules

You could limit SSH access to only certain IPs, a jump or bastion host for instance, or your office IP range. To do so, open the `terraform/main.tf` file and update the `inbound_rule` block of the `digitalocean_firewall` `management` resource:

```terraform
inbound_rule = [
  {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  },
]
```

Put the correct address or range in place of the `0.0.0.0/0` catchall in `source_addresses`. If you've already provisioned your infrastructure, save the file and rerun `bp terraform apply` from the `terraform` directory to apply the changes.

### Changing Datacenters

To launch this infrastructure in a different datacenter, again open the `terraform/main.tf` file. Update the `region` key of the two `digitalocean_droplet` resources. Both Droplets need to be in the same region, as private networking only works within one region.

You can list out all available regions using `doctl`:

```
bp doctl compute region list
```

### Changing Backup Timing

By default, your Cachet installation will create a new backup once a day, and will send an email if anything goes wrong. It will also monitor existing backup files and email with any problems. So if, for instance, you accidentally deleted your Spaces bucket, you would be notified of the issue.

This backup schedule is handled in the `roles/cachet/files/console-kernel.php` file in the Blueprint repository. Look for the `schedule` function if you want to adjust when these tasks run:

```php
protected function schedule(Schedule $schedule)
{
    $schedule->command('queue:work --sleep=3 --tries=3')->everyMinute();
    $schedule->command('backup:clean')->daily()->at('01:43');
    $schedule->command('backup:run')->daily()->at('02:24');
    $schedule->command('backup:monitor')->daily()->at('05:19');
}
```

This function is kicked off every minute from an entry in the `www-data` user's crontab. The `queue:work` task handles the mail queue and should not be adjusted or removed.

> **Note:** after updating any files or templates in the `cachet` role, you'll need to rerun `bp ansible-playbook site.yml --ask-vault-pass` to push the changes to the server.

## Common Issues

### Let's Encrypt

If you get an error during the `Get Let's Encrypt certificate` Ansible task, there is most likely an issue with your DNS configuration. Either your records are not pointing to the correct IP address, or perhaps you updated an existing record and the changes are taking a while to propagate. Double-check the IP addresses you entered, or try the `ansible-playbook` command again after giving the DNS system some more time to update.
