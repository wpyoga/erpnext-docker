# erpnext-docker

Deploy ERPNext on Docker, optionally with Tailscale.

Docker here can mean Podman as well. It's just that the world has standardized on Docker.

Tailscale here can also mean any similar VPN system. Even OpenVPN can work, albeit with a different structure.

## Basic Concepts

ERPNext is an ERP application that is built on top of the Frappe framework.

This is the general order of operations to set up ERPNext:
1. Deploy a Frappe project
1. Install ERPNext into the project
1. Create a site within the project
1. Install ERPNext into the site

All the steps above require the use of the bench CLI, which was made specifically to manage Frappe projects. It can deploy a Frappe project, install applications (not just ERPNext) into the project, create a site within the project, and install applications in the project into the site.

A Frappe project always has a Frappe application inside it. It is automatically installed when deploying a Frappe project. This Frappe application is then imported by other apps (such as ERPNext).

A Frappe site is a deployment instance hosted inside the deployed Frappe project. Installing an app means making the app available within the site. This site is what users actually interact with.

Before deploying a Frappe project, dependencies must be installed. Aside from the Python runtime, the Frappe framework needs a database (MariaDB by default) and a cache (Redis). Individual applications can have their own external dependencies, which need to be installed separately.

To make user access efficient, a reverse proxy (usually Nginx) handles incoming connections. The official ERPNext Docker image bundles Nginx and runs it in a container named *frontend*. In reality it's just Nginx with ERPNext-specific configuration.

## Frappe with Docker

Deploying a Frappe project is easy with Docker. However, since Docker containers are not meant to be modified after deployment. Therefore, the recommended way to deploy ERPNext with Docker is to deploy a Frappe project, then install the ERPNext application into it. A nice bonus is that deploying it this way simplifies upgrades later on. The downside is that in order to install more Frappe applications, we have to rebuild the deployment image.

The Frappe project has provided official ERPNext Docker images on Docker Hub, so we can just use those. It has been prepared in such a way that ERPNext deployment is as simple as it gets. The image:
- Has bench installed, which we can use to manage deployment
- Has MariaDB and PostgreSQL client utilities installed
- Has a Frappe project deployed in /home/frappe/frappe-bench
- Has ERPNext installed inside the Frappe project
- Has multiple services integrated:
  - frontend: Nginx reverse proxy
  - backend: Gunicorn server
  - websocket: Node.js web socket
  - scheduler: Frappe scheduler
  - queue-long: Frappe worker that priorities longer jobs
  - queue-short: Frappe worker that handles short and normal jobs

Note that aside from Nginx, the other services are all components of the deployed Frappe project. Also note that while the Nginx binary is not a custom build, its configuration is very tightly coupled to Frappe.

## Tailscale

To allow access to the ERPNext instance from within a Tailscale network, we can use a Tailscale sidecar arrangement. In this arrangement, a Tailscale container is added to the Docker compose file. No ports are forwarded from the Docker containers to the host, and all incoming connections come in through the Tailscale container. The Frappe project will then only be accessible within the tailnet.

## Multi Tenancy

It is possible to do multi tenancy with Frappe and ERPNext. In the case of ERPNext, this means one server can host the ERP system of multiple organizations.

The easiest way to do this is to set up multiple complete Frappe projects, so that each project hosts a single organization. Each project can be distinct from the others, can have different dependency versions, and different custom code for each one. But this is very resource-intensive, as the database and backend instances are duplicated.

Another method is to set up a single database and cache instance, but with multiple Frappe projects (benches). This is a bit leaner on resources, and allows different ERPNext versions to be implemented for each tenant. This is called multi-bench multi-tenancy.

The least resource-intensive method is to set up a single Frappe project, then create multiple sites under that project. Updates are easy to apply. This is called multi-site multi-tenancy. By default, sites are accessible by its name (which can be a hostname or an FQDN).

### Multi Tenant HTTPS with Tailscale

This is suitable for personal use or small organizations where finances and business processes are compartmentalized. Multiple ERPNext sites are hosted as subdomains within a single domain. One simple setup to achieve this would be:
- Wildcard sub-subdomain on the DNS server (\*.sub.example.com) pointing to Tailscale node IP
- API access to registrar's DNS server
- Caddy with appropriate DNS plugin for the registrar
- Tailscale serving TCP port 443 and forwarding connections to Caddy port 443

When the containers are first spun up, Caddy starts with a blank configuration. As sites are added, Caddy configuration is fleshed out, and it starts requesting TLS certificates using the DNS-01 challenge. This is the only challenge we can use, since the domains are only accessible inside the Tailnet.

When a client visits a site, the incoming request first goes though Tailscale. It is then forwarded to Caddy, which responds with a signed certificate. The client verifies that the certificate is indeed valid for the domain, and proceeds. The client's request is then forwarded to the Frappe frontend container, which is just an Nginx instance forwarding requests to the Frappe container instance. Because the client requests a specific domain, it is passed along as the HTTP `Host:` header. This is how the Frappe backend instance knows which site is being requested.

Note: QUIC is not supported because Tailscale does not support forwarding UDP ports.

### Multiple domains with a single Tailscale entry point

This is applicable for an organization with multiple divisions. The setup would be:
- One subdomain per site (multiple sites can share one subdomain)
- API access to each site's registrar DNS server
- Caddy with all DNS plugins enabled
- Tailscale serving TCP port 443 and forwarding connections to Caddy port 443

The process of creating a site then goes like this:
1. Add an A record to the registrar's DNS if it's not a wildcard domain
1. Update Caddy config with the new site
1. `bench new-site`

### Multiple domains on a single server with a Public IP address

This is actually a common use case for independent contractors selling ERPNext hosting services. The setup looks like this:
- One subdomain per site
- API access to each site's registrar DNS server -- OR -- the server itself hosts a DNS server to respond to DNS-01 challenges
- Caddy with all DNS plugins enabled, directly facing the Internet.

The process of creating a site then goes like this:
1. Add an A record to the registrar's DNS if it's not a wildcard domain
1. Update Caddy config with the new site
1. `bench new-site` with a randomized admin password

There are multiple ways to expand this concept:
- Have multiple servers behind a reverse proxy / load balancer
- Have multiple servers with multiple Public IP addresses
- Web dashboard to manage the deployments

## Helper scripts

Helper scripts are provided in this repo. These configurations are supported:
- ERPNext v15
- Serve on a public IP address or within a Tailscale network
- DNS hosted on Cloudflare or Porkbun

To use the scripts, first plan out the project and prepare these files:
- `build.env`: general configuration
- `project.env`: project-specific parameters
- `secrets.env`: passwords and keys
- `sites/*.env`: site-specific configuration, including DNS keys etc (one site per file)

Then, run these scripts in order:
1. `10-checkout-repo.sh`: Clone (shallow) the official `frappe_docker` repo
1. `30-render-compose.sh`: Fully render out compose.yaml from the `frappe_docker` repo
1. `40-initialize-project.sh`: Deploy the project (spin up containers)
   - If using Tailscale, be sure to check the Tailscale container logs and add the node to the Tailnet
1. `70-create-sites.sh`: Create the sites, including DNS records

During each step, check the console messages and Docker logs, and see if there are any errors or warnings. [Open an issue](../../issues) if there are problems.

