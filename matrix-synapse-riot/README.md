Matrix Synapse + Riot
===================

## Provision Matrix homeserver with Riot frontend

We will be using the following tools and services:

* [Digital Ocean](https://www.digitalocean.com) as the virtual machine provider
* [Terraform](https://www.terraform.io) to provision the cloud servers
* [Let's Encrypt](https://letsencrypt.org) to get SSL certificates for HTTPS

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

    By default, this will set up the frontend to be accessible from the internet and cjdns

    You may also choose not install cjdns by changing `cjdns` variable to `0`
    
    For example:

        terraform apply -var "cjdns=false"

    From your browser, login to your Digital Ocean dashboard and find your new VMs tagged
    with `matrix-homeserver`.

    When it is done you will see a temporary password. At your first login you will be prompted to
    change your password.
   
    We recommand you do not delete your access token as it is needed to renew Let's Encrypt certificates.

## Maintaining and Updating
For the below instructions we will be using tomesh.net as the domain.
Please substitute tomesh.net with the domain name you set up with.
 
### Update Synapse Version
1. SSH into **matrix.tomesh.net**

1. Enter the virtualenv from the synapse user:

	```
	# sudo -i -u synapse
	# cd ~/.synapse
	# source ./bin/activate
	```
1. Stop the Synapse server with `synctl stop`.

1. Update with the following command where `VERSION` can be a branch like `master` or `develop`, or a release tag like `v0.34.0`, or a commit hash:

	```
	# pip install --upgrade --process-dependency-links https://github.com/matrix-org/synapse/tarball/VERSION
	```

1. Start the Synapse server again with `synctl start`.

### Update Riot Web Client
1. SSH into **matrix.tomesh.net**

1. Get a root shell with `sudo -i`.

1. Download the pre-compiled [Riot Web release](https://github.com/vector-im/riot-web/releases):

	```
	# wget https://github.com/vector-im/riot-web/releases/download/v0.17.8/riot-v0.17.8.tar.gz
	```

1. Remove old Riot Client
	```
	# rm -r /var/www/chat.tomesh.net/public/*
	```
1. Extract **riot-v0.17.8.tar.gz** into **/var/www/chat.tomesh.net/public**:

	```
	# tar xf riot-v0.17.8.tar.gz -C /var/www/chat.tomesh.net/public --strip-components 1
	```

1. Create **config.json** in /var/www/chat.tomesh.net/public/ with the following lines, so it is used in place of the default **config.sample.json**:

	```
	{
	    "default_hs_url": "https://matrix.tomesh.net",
	    "default_is_url": "https://vector.im",
	    "disable_custom_urls": false,
	    "disable_guests": false,
	    "disable_login_language_selector": false,
	    "disable_3pid_login": false,
	    "brand": "Riot",
	    "integrations_ui_url": "https://scalar.vector.im/",
	    "integrations_rest_url": "https://scalar.vector.im/api",
	    "integrations_jitsi_widget_url": "https://scalar.vector.im/api/widgets/jitsi.html",
	    "bug_report_endpoint_url": "https://riot.im/bugreports/submit",
	    "features": {
		"feature_groups": "labs",
		"feature_pinning": "labs"
	    },
	    "default_federate": true,
	    "welcomePageUrl": "home.html",
	    "default_theme": "light",
	    "roomDirectory": {
		"servers": [
		    "tomesh.net",
		    "matrix.org"
		]
	    },
	    "welcomeUserId": "@riot-bot:matrix.org",
	    "piwik": {
		"url": "https://piwik.riot.im/",
		"whitelistedHSUrls": ["https://matrix.org"],
		"whitelistedISUrls": ["https://vector.im", "https://matrix.org"],
		"siteId": 1
	    },
	    "enable_presence_by_hs_url": {
		"https://matrix.org": false
	    }
	}
	```

1. Run `chown -R www-data:www-data /var/www/` to ensure that www-data have full access.

### Grant Synapse User Admin Rights
1. Switch to Postgres user `sudo -i -u postgres`

1. Load CLI and connect to Synapse database `psql -d synapse`

1. Run the query to make the user an admin replace USERNAME with the username of the user:
	```
	UPDATE users SET admin=1 WHERE name LIKE '@USERNAME:tomesh.net';
	```
### Purging Old Posts and Media Files From One Year Ago
1. Login as an admin user at https://matrix.tomesh.net/ and copy your `Access token`

1. SSH into **matrix.tomesh.net**

1. Switch to the synapse user `sudo -i -u synapse`

1. `cd ~/.synapse/`

1. Put your `Access token` into an variable called `access_token`
	```
	# access_token=ABCD1234...
	```

1. Run the API call to purge old posts e.g. `#tomesh:tomesh.net` channel with the `Internal room ID:` `!FsFLbKGMcUXEMBxZdu:tomesh.net`. To purge another room replace the ID with that room's ID:

	```
	# curl -XPOST -d '{"delete_local_events": true, "purge_up_to_ts": '$(echo $(($(date --date="1 year ago" -u +%s%N)/1000000)))' }' 'http://localhost:8008/_matrix/client/r0/admin/purge_history/!FsFLbKGMcUXEMBxZdu:tomesh.net?access_token='$access_token
	```

1. Optionally you can remove all remote content by running:
	```
	curl -XPOST -d '{}' "http://localhost:8008/_matrix/client/r0/admin/purge_media_cache?before_ts=$(echo $(($(date -u +%s%N)/1000000)))&access_token=$access_token"`
	```
1. Logout of the synapse user

1. Switch to Postgres user `sudo -i -u postgres`

1. Load CLI and connect to Synapse database `psql -d synapse`

1. Run the command `VACUUM;`

1. Logout of the database and the postgres user and return back to synpase shell

1. Delete old media files by running the following commands:
	```
	cd ~/.synapse/media_store/local_content
	find * -mindepth 1 -mtime +365 -delete
	```
