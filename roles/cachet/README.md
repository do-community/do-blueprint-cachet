# cachet

An Ansible role to set up the [Cachet](https://cachethq.io/) open source status page app. Includes SSL support via Let's Encrypt, and automatic local backups with optional offsite backups to DigitalOcean [Spaces](https://www.digitalocean.com/products/spaces/) object storage. This role is intended to be used as part of [do-blueprint-cachet](https://github.com/do-community/do-blueprint-cachet).

## Requirements

Requires a MySQL server. Also depends on private networking and network-based firewalls to be secure. Please look at [do-blueprint-cachet](https://github.com/do-community/do-blueprint-cachet) for the complete solution.

## Role Variables

```
# Type: string
# Default: (none)
# Description: The hostname of your status page.
cachet_hostname: status.example.com

# Type: string
# Default: v2.3.13
# Description: Which version of Cachet to install. Only tested w/ v2.3.13.
cachet_version: v2.3.13

# Type: string
# Default: (none)
# Description: An email to register w/ the Let's Encrypt service.
cachet_letsencrypt_email: sammy@example.com

# Type: string
# Default: (none)
# Description: The email that will send backup service errors messages.
cachet_backup_emails_from: sammy@example.com

# Type: string
# Default: (none)
# Description: The email to receive backup service error messages.
cachet_backup_emails_to: sammy@example.com

# Type: string
# Default: (none)
# Description: A key for the Spaces object storage service.
cachet_spaces_key: OCC6VHGUUISUKVQCFEJM

# Type: string
# Default: (none)
# Description: A secret for the Spaces object storage service.
cachet_spaces_secret: ZEF6t7YChgx2AedOKhVnh+RsEfo6bZYf0FSxJq1el3c

# Type: string
# Default: (none)
# Description: The endpoint of your Spaces bucket.
cachet_spaces_endpoint: https://nyc3.digitaloceanspaces.com

# Type: string
# Default: (none)
# Description: Your Spaces bucket name
cachet_spaces_bucket: bucket3000

# Type: various
# Default: various
# Description: The remainder of this role's variables are directly passed into
#   Cachet's `.env` environment variable file. Refer to Cachet's documentation
#   for info on expected values: https://docs.cachethq.io/docs/installing-cachet
cachet_app_env: production
cachet_app_debug: false
cachet_app_url: https://status.example.com
cachet_app_key: base64:3d7eUI7GsoKqLYkaXRxUCR4gXzK5qZLhJ5cDYRDiMrk=
cachet_db_host: 203.0.113.11
cachet_db_port: 3306
cachet_db_database: dbname
cachet_db_username: dbuser
cachet_db_password: dbpassword
cachet_mail_driver: smtp
cachet_mail_host: mail.example.com
cachet_mail_port: 25
cachet_mail_username: postmaster
cachet_mail_password: mailpassword
cachet_mail_from_address: mail@example.com
cachet_mail_from_name: Postmaster
cachet_mail_encryption: tls
cachet_cache_driver: apc
cachet_session_driver: apc
cachet_queue_driver: database
cachet_cachet_emoji: false
cachet_redis_host: 203.0.113.12
cachet_redis_database: dbname
cachet_redis_port: 6379
cachet_github_token:
```

## Dependencies

None

## Example Playbook

An example use of this role can be found in the [do-blueprint-cachet](https://github.com/do-community/do-blueprint-cachet) repository.

## License

MIT

## Author Information

DigitalOcean Community
