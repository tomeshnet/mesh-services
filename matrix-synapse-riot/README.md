Matrix Synapse + Riot
=====================

## Provision Matrix homeserver with Riot frontend

We will be using the following tools and services:

* [Digital Ocean](https://www.digitalocean.com) as the virtual machine and or DNS provider
* [Terraform](https://www.terraform.io) to provision the cloud servers
* [Let's Encrypt](https://letsencrypt.org) to get SSL certificates for HTTPS
* [Proxmox](https://www.proxmox.com) as self-hosted virtual machine option

The following steps assume you have a Digital Ocean account.

1. Clone this repository and work from the `terraform` directory:

        git clone https://github.com/tomeshnet/mesh-services.git
        cd mesh-services/matrix-synapse-riot/terraform

1. From your domain name registrar, point name servers to Digital Ocean's name servers:

        ns1.digitalocean.com
        ns2.digitalocean.com
        ns3.digitalocean.com

1. Create a new domain in Digital Ocean Networking tab

1. Then store the domain name in your local environment:

        echo -n YOUR_DOMAIN_NAME > .keys/domain_name

1. Obtain a read-write access token from your Digital Ocean account's `API` tab, then store
    it in your local environment:

        echo -n YOUR_DIGITAL_OCEAN_ACCESS_TOKEN > .keys/do_token

1. Generate RSA keys to access your Matrix VM:

        ssh-keygen -t rsa -f .keys/id_rsa

## Digital Ocean Specific Steps
1.  Rename main-digital-ocean.tf.txt to main.tf

         mv main-digital-ocean.tf.txt main.tf

1.  Add the SSH key to your Digital Ocean account under `Settings > Security`, then copy the
    SSH fingerprint to your local environment:

        echo -n YOUR_SSH_FINGERPRINT > .keys/ssh_fingerprint

1. [Download Terraform](https://www.terraform.io/intro/getting-started/install.html), add it to
    your path. On Linux it would look something like this:

        https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip
        unzip terraform_0.11.13_linux_amd64.zip
        mv terraform /usr/local/bin

    Then run initialization from our `terraform` working directory:

        terraform init

## Proxmox Specific Steps
1.  Rename main-digital-ocean.tf.txt to main.tf

         mv main-proxmox.tf.txt main.tf

1.  Set your host IP information

        echo -n YOUR_IPV4_ADDRESS > .keys/interface_ip
        echo -n YOUR_IPV4_GATEWAY > .keys/interface_gw
        echo -n YOUR_IPV4_NETMASK > .keys/interface_ip_netmask (for example 24)
        echo -n YOUR_IPV6_ADDRESS > .keys/interface_ip6
        echo -n YOUR_IPV6_GATEWAY > .keys/interface_gw6
        echo -n YOUR_IPV6_NETMASK > .keys/interface_ip6_netmask (for example 64)

1.  Set your DNS resolver

        echo -n YOUR_RESOLVER_IP_ADDRESS > .keys/nameserver

1. [Download Terraform](https://www.terraform.io/intro/getting-started/install.html), add it to
    your path. On Linux it would look something like this:

        https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip
        unzip terraform_0.11.13_linux_amd64.zip
        mv terraform /usr/local/bin

    Install the Proxmox plug-in

        go get github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provider-proxmox
        go get github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provisioner-proxmox

    To prevent timeout errors change TaskStatusCheckInterval to 30 seconds in ~/go/src/github.com/Telmate/proxmox-api-go/proxmox/client.go

        go install github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provider-proxmox
        go install github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provisioner-proxmox
        mkdir -p ~/.terraform.d/plugins
        cp ~/go/bin/terraform-provider-proxmox ~/go/bin/terraform-provisioner-proxmox ~/.terraform.d/plugins/

    Then run initialization from our `terraform` working directory:

        terraform init

## Provision the server
1. Provision the server by running:

        terraform apply

    By default, this will set up the frontend to be accessible from the internet, cjdns, and yggdrasil

    You may also choose to not install cjdns and or Yggdrasil by changing their variables to `false`, for example:

        terraform apply -var "cjdns=false" -var "yggdrasil=false"

1. From your browser, login to your dashboard and find your new VM.
   When it is done you will see a temporary password. At your first login you will
    be prompted to change your password. We recommmend that you do not delete your access token as it is
    needed to renew Let's Encrypt certificates

## Maintaining and updating

For the below instructions we will be using the `tomesh.net` as an example. Please substitute `tomesh.net` with
the domain name you are setting up.
 
### Updating Synapse version

1. SSH into **matrix.tomesh.net**

1. Update Synapse using Debian's apt command

        sudo apt update && sudo apt dist-upgrade -y

### Updating Riot Web client

1. SSH into **matrix.tomesh.net**

1. Get a root shell with `sudo -i`

1. Download the pre-compiled [Riot Web release](https://github.com/vector-im/riot-web/releases):

        wget https://github.com/vector-im/riot-web/releases/download/v1.1.1/riot-v1.1.1.tar.gz

1. Backup config file
        cp /var/www/chat.tomesh.net/public/config.json /root/riot-config.json

1. Remove old Riot client:

        rm -r /var/www/chat.tomesh.net/public/*

1. Extract **riot-v1.1.1.tar.gz** into **/var/www/chat.tomesh.net/public**:

        tar xf riot-v1.1.1.tar.gz -C /var/www/chat.tomesh.net/public --strip-components 1

1. Restore config file

        cp /root/riot-config.json /var/www/chat.tomesh.net/public/config.json

1. Run `chown -R www-data:www-data /var/www/` to ensure that www-data have full access

### Granting Synapse user admin rights

1. Switch to Postgres user `sudo -i -u postgres`

1. Load CLI and connect to Synapse database `psql -d synapse`

1. Run the query to make the user an admin replace USERNAME with the username of the user:

        UPDATE users SET admin=1 WHERE name LIKE '@USERNAME:tomesh.net';

### Purging old posts and media files from one year ago

1. Login as an admin user at https://chat.tomesh.net and copy your `Access token`

1. SSH into **matrix.tomesh.net**

1. Switch to the synapse user `sudo -i -u synapse`

1. Enter the `.synapse` directory `cd ~/.synapse/`

1. Put your `Access token` into a variable called `access_token`:

        access_token=ABCD1234...

1. Run the API call to purge old posts (e.g. `#tomesh:tomesh.net` channel with the `Internal room ID:` `!FsFLbKGMcUXEMBxZdu:tomesh.net`).
    To purge another room, replace the ID with that room's ID:

        curl -XPOST -d '{"delete_local_events": true, "purge_up_to_ts": '$(echo $(($(date --date="1 year ago" -u +%s%N)/1000000)))' }' 'http://localhost:8008/_matrix/client/r0/admin/purge_history/!FsFLbKGMcUXEMBxZdu:tomesh.net?access_token='$access_token

1. Optionally you can remove all remote content by running:

        curl -XPOST -d '{}' "http://localhost:8008/_matrix/client/r0/admin/purge_media_cache?before_ts=$(echo $(($(date -u +%s%N)/1000000)))&access_token=$access_token"`

1. Logout of the synapse user

1. Switch to Postgres user `sudo -i -u postgres`

1. Load CLI and connect to Synapse database `psql -d synapse`

1. Run the command `VACUUM;`

1. Logout of the database and the Postgres user and return back to Synapse shell

1. Delete old media files by running the following commands:

        cd ~/.synapse/media_store/local_content
        find * -mindepth 1 -mtime +365 -delete