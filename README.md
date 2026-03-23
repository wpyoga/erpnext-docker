# erpnext-docker
Deploy ERPNext on Docker

Docker here can mean Podman as well. It's just that the world has standardized on Docker.

## Basic Concepts

ERPNext is an ERP application that runs on top of the Frappe framework and uses the framework. It is not built *with* the Frappe framework, unlike a Laravel app or a Next.js app. Think of it like Nginx (the application) built on top of an Alpine Linux docker image (the framework). Only in this case, the application cannot run without or outside of the framework.

To run ERPNext, first we have to deploy a Frappe project. This comes with its own dependencies, namely a database (MariaDB by default) and a cache (Redis).

Then, we install the ERPNext into the project.

Lastly, we create a site within the Frappe project. This site will have all the applications that we have installed in the project. In our case, that will be only ERPNext.

## Frappe with Docker

With Docker, there is a caveat: Docker containers are immutable. Any changes made in runtime will disappear once the container is stopped. So the ERPNext app has to be integrated inside the Docker image, along with the Frappe project.

The Frappe project has provided ERPNext Docker images on Docker Hub, so we can just use those.

## Tailscale

TODO

## HTTPS with Tailscale

TODO







