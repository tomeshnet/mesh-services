Matrix / Riot
===================

#### Provision Matrix homeserver with Riot frontend

We will be using the following tools and services:

* [Digital Ocean](https://www.digitalocean.com) as the virtual machine provider
* [Terraform](https://www.terraform.io) to provision the cloud servers
* [Let's Encrypt](https://letsencrypt.org) to get SSL certificates for HTTPS

The following steps assume you have a Digital Ocean account.

1. Clone this repository and work from the `terraform` directory:

        git clone https://github.com/tomeshnet/node-recipes.git
        cd node-recipes/synapse-chat/terraform

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

1. Generate RSA keys to access your Digital Ocean VMs:

        ssh-keygen -t rsa -f .keys/id_rsa

    Add the SSH key to your Digital Ocean account under `Settings > Security`, then copy the
    SSH fingerprint to your local environment:

        echo -n YOUR_SSH_FINGERPRINT > .keys/ssh_fingerprint

1. [Download Terraform](https://www.terraform.io/intro/getting-started/install.html), add it to
    your path. On Linux it would look something like this:

        https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip
        unzip terraform_0.11.10_linux_amd64.zip
        mv terraform /usr/bin

    Then run initialization from our `terraform` working directory:

        terraform init

1. Provision the server by running:

        terraform apply

    By default, this will setup the frontend to be accessable from CJDNS by installing CJDNS and getting
    valid certificates from Let's Encrypt. 
    

    You may also choose not install CJDNS by changing `cjdns` variable to `0`
    
    For example:

        terraform apply -var "cjdns=0"

    From your browser, login to your Digital Ocean dashboard and find your new VMs tagged
    with `matrix-homeserver`.

   When it is done you will see a temporary password. At your first login you will be prompted to
   change your password
   
   We recommand you do not delete your access token as it is needed to renew Let's Encrypt certificates.
