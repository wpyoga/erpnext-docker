# erpnext-docker
Deploy ERPNext on Docker

Docker here can mean Podman as well. It's just that the world has standardized on Docker.

## Basic Concepts

ERPNext is an ERP application that runs on top of the Frappe framework and uses the framework. It is not built *with* the Frappe framework, unlike a Laravel app or a Next.js app. Think of it like Nginx (the application) built on top of an Alpine Linux docker image (the framework). Only in this case, the application cannot run without or outside of the framework.

To run ERPNext, first we have to deploy a Frappe project. This comes with its own dependencies, namely a database (MariaDB by default) and a cache (Redis).

Then, we install the ERPNext into the project.

Lastly, we create a site within the Frappe project. This site will have all the applications that we have installed in the project. In our case, that will be only ERPNext.

## Frappe with Docker

With Docker, there is a caveat: Docker images are immutable. Any changes made at runtime will disappear once the container is removed. So if the Docker image is updated, changes will be lost. Therefore the ERPNext app has to be integrated inside the Docker image, along with the Frappe project.

The Frappe project has provided ERPNext Docker images on Docker Hub, so we can just use those.

## Tailscale

To allow access to the ERPNext instance from within a Tailscale network, we can use a Tailscale sidecar arrangement. In this arrangement, a Tailscale container is added to the Docker compose file. No ports are forwarded from the Docker containers to the host, and all incoming connections come in through the Tailscale container. The Frappe project will then only be accessible within the tailnet.

## HTTPS with Tailscale

TODO

## Multi Tenancy

It is possible to do multi tenancy with Frappe and ERPNext. In the case of ERPNext, this means one server can host the ERP system of multiple organizations.

The easiest way to do this is to set up multiple complete Frappe projects, so that each project hosts a single organization. Each project can be distinct from the others, can have different dependency versions, and different custom code for each one. But this is very resource-intensive, as the database and backend instances are duplicated.

Another method is to set up a single database and cache instance, but with multiple Frappe projects (benches). This is a bit leaner on resources, and allows different ERPNext versions to be implemented for each tenant. This is called multi-bench multi-tenancy.

The least resource-intensive method is to set up a single Frappe project, then create multiple sites under that project. Updates are easy to apply. This is called multi-site multi-tenancy. By default, sites are accessible by its name (which can be a hostname or an FQDN).











