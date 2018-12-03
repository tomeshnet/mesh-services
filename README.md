# Mesh Services

We use [Terraform](https://terraform.io) to provision self-hosted applications that are accessible over our meshnet and the Internet. At the moment, we provision services to [Digital Ocean](https://digitalocean.com) VMs and our meshnet is virtualized on [cjdns](https://github.com/cjdelisle/cjdns/).

Our community relies on these services to organize day-to-day activities and develop our meshnet. By keeping configuration as code and automating provisioning of these shared infrastructures, we hope to distribute infrastructure management knowledge among Toronto Mesh, and share this with other groups organizing their local meshnet efforts.

## Toronto Mesh Services

At the moment, the following services are deployed from this repositiory:

| Service                     | Mesh link                   | Internet link             |
|:----------------------------|:----------------------------|:--------------------------|
| [Matrix](http://matrix.org) | https://h.matrix.tomesh.net | https://matrix.tomesh.net |
| [Riot](https://riot.im)     | https://h.chat.tomesh.net   | https://chat.tomesh.net   |

## Hopes & Dreams

```
NOW

+------------------+
| Digital Ocean VM |
|                  +--> Meshnet over cjdns IPv6 tunneled over Internet
| +--------------+ |
| | Self-hosted  | |
| | Applications | +--> Internet over public IPv4 and IPv6
| +--------------+ |
+------------------+

SHORT-TERM

+------------------+
| Home Server VM   |
|                  +--> Meshnet over cjdns IPv6 tunneled over Internet
| +--------------+ |
| | Federated    | |
| | Applications | +--> Internet over public IPv4 and IPv6 (hopefully)
| +--------------+ |
+------------------+

LONG-TERM

+------------------+
| Low-cost Devices |
|                  +--> Meshnet over cjdns IPv6 over community links
| +--------------+ |
| | Peer-to-peer | |
| | Applications | +--> Internet over public IPv4 and IPv6 (maybe)
| +--------------+ |
+------------------+
```

## Questions

>. . . but isn't Digital Ocean just another centralized cloud provider?

A centralized cloud provider solves two problems for us: _reachability_ and _reliability_, which our meshnet is not yet able to produce. Once our meshnet can route network traffic without a public IPv4 address and applications are designed to operate in distributed environments, we can start provisioning on local targets and the transition will be smooth if we are already familiar with a virtualized version of a meshnet.

>. . . but isn't the future peer-to-peer?

The applications we provision are _self-hosted_, but most expect having multiple users share a single instance. Some examples are [Matrix](https://matrix.org) and [Loomio](https://www.loomio.org). Server outage usually means the users of that instance are unable to use the service, wheras truly peer-to-peer applications usually are designed expecting ubiquitous node outages. As we adopt more production-ready peer-to-peer applications, we can imagine targeting deployment to local devices like Raspberry Pis with less demand on reliability.

>. . . but why Terraform instead of _X_?

The group in Toronto became familiar with Terraform and the primary use of this repository is for us to redeploy our own shared infrastructure. If you already have a favourite provisioner it should be relatively trivial to port since much of the complexity is in each `bootstrap.sh`.
