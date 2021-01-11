# `tjpotenza/kubernetes-modules`

A few modules, scripts, and tools I use for managing personal Kubernetes clusters built around Rancher's [k3s](https://k3s.io/).

*Disclaimer: This project isn't \*really\* meant for consumption or serious use outside of my own.  It's more a portfolio piece, an opportunity to exercise a bunch of technologies, and a personal reference for a bunch of Terraform-isms and Kubernetes-isms.  I make a bunch of choices and compromises that are specific to my use-cases, and most likely will make many breaking changes to these modules.*

*Disclaimer #2: These modules and these docs are not complete, and very well may never be.*

## Why?

To provide a platform for several of my hobby projects, while also being one of those hobby projects itself.  I also wanted the opportunity to play around with larger scale multi-cluster orchestration patterns while keeping my personal AWS bill at somewhat "hobby project" levels, so _many_ of the design choices here are made with cost-effectively facilitating that goal in mind.

## General Structure

### Overview

There's a diagram available [here](./docs) that may help to paint a better picture, however the super high-level summary is:

* Several clusters share much of the same networking config and resources.
* There are two `Route 53 Zones` for the same domain; one internal and one external.  The internal zone has a wildcard record pointing directly at a shared internal `ALB`.  The external zone has a wildcard record pointing toward a `Global Accelerator`, which itself is configured to forward traffic on ports `80` and `443` to the shared ALB.
* The shared `ALB` supports two main categories of traffic: `public` (world-accessible) and `private` (restricted to private CIDRs from within the VPC and personal IPs).
* Every cluster gets a default `Target Group` and `Listener Rules` registered for `private` traffic to  `*--{cluster_name}.{dns_zone}`.
* Service endpoints create a `Listener Rule` and `Target Group` that can be associated with one cluster or load balanced across several clusters.  Each endpoint may be `public` or `private`.

## Module-Specific Notes

### Endpoint

#### ALB Target Group Healthchecks
The default healthchecks associated with the service module are just checking the health of Kubernetes itself on each instance.  This is totally fine for cases where only one cluster is attached, or when all attached clusters are guaranteed to be running a copy of that service.  If at any time one or more cluster in the Target Group exists without running a copy of that service (say when a cluster is first deployed), all requests the ALB routes to it will fail.  ALB Target Group Healthchecks can be configured for each service so that instances will only be routable if they are able to handle requests for the service, but there's a small catch.

ALB Target Group healthchecks are currently not able to pass `Host` headers, and therefore cannot be used with `ingress`-based services in Kubernetes.  ALB Target Group healthchecks can be used for a service if the corresponding service's `Service (K8S Resource)` is configured with `type: NodePort`, and the listener pointed to that port instead of its default `80`.

### Restrictions, Quirks, and Assumptions
* `ALB`'s do not currently support TLS passthrough, so the Control Plane API endpoint cannot be fronted by the same `ALB` as all other traffic.  An `NLB` would be a better solution if cost weren't a consideration, however I've instead opted to just point a DNS records at control plane instances instead.  The biggest pain point is that `terraform` must be re-apply'd if any of the control plane nodes get replaced, which felt like an acceptable trade-off for $15 a month considering the fairly limited impact of that endpoint (used for local `kubectl` commands and when a worker joins the cluster).
* The nodes must be in public