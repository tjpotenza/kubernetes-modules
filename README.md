# `tjpotenza/kubernetes-modules`

A few modules, scripts, and tools I use for managing personal Kubernetes clusters built around Rancher's [k3s](https://k3s.io/).

*Disclaimer: This project isn't \*really\* meant for consumption or serious use outside of my own.  It's more a portfolio piece, an opportunity to exercise a bunch of technologies, and a personal reference for a bunch of Terraform-isms and Kubernetes-isms.  I make a bunch of choices and compromises that are specific to my use-cases, and most likely will make many breaking changes to these modules.*

*Disclaimer #2: These modules and these docs are not complete, and very well may never be.*

## Why?

To provide a platform for several of my hobby projects, while also being one of those hobby projects itself.  I also wanted the opportunity to play around with larger scale multi-cluster orchestration patterns while keeping my personal AWS bill at somewhat "hobby project" levels, so _many_ of the design choices here are made with cost-effectively facilitating that goal in mind.

## General Structure

### Overview

The super high-level summary of how these pieces fit together is as follows:
* The `control_plane` module creates a baseline cluster and a handful of auxiliary resources.
* The `workers` module creates a group of nodes that can be attached to an existing `control_plane` cluster.
* The `shared_endpoint` module creates a DNS record and ALB Listener Rule for a service that can be running on one or more cluster.

Not currently managed in this repo are:
* The DNS Zones.
* The Shared ALB(s) per-region, and the security group that allows ingress from them.
* A Route53 alias record of format `*.{region}.{dns_zone}` pointed to the Shared ALB(s).

#### Cluster Endpoints
```
+--------------------------------+----------------------+-----------------------------------------+--------------------------+
|  Route 53 (Shared)             | ALB (Shared)         | ALB Listeners (Per Cluster)             | Instances (Per Cluster)  |
+--------------------------------+----------------------+-----------------------------------------+--------------------------+
|                                                     /-> [ *--alpha.us-east-1.example.com ] -----> [ Alpha Target Group ]   |
| [ *.us-east-1.example.com ] ---> ALB (us-east-1) --|                                                                       |
|                                                     \-> [ *--bravo.us-east-1.example.com ] -----> [ Bravo Target Group ]   |
|                                                                                                                            |
|                                                     /-> [ *--charlie.us-west-2.example.com ] ---> [ Charlie Target Group ] |
| [ *.us-west-2.example.com ] ---> ALB (us-west-2) --|                                                                       |
|                                                     \-> [ *--delta.us-west-2.example.com ] -----> [ Delta Target Group ]   |
+----------------------------------------------------------------------------------------------------------------------------+
```

#### Shared Endpoints
```
+--------------------------------+---------------------+-----------------------------------------+--------------------------+
| Route 53 (Per Endpoint)        | ALB (Shared)        | ALB Listeners (Per Endpoint)            | Instances (Per Cluster)  |
+--------------------------------+---------------------+-----------------------------------------+--------------------------+
|                                                                                              /-> [ Alpha Target Group ]   |
| [ blog.example.com ] ----------> ALB (us-east-1) ----> [ blog.example.com ] ----------------|                             |
| (Latency-based, us-east-1)                                                                   \-> [ Bravo Target Group ]   |
|                                                                                                                           |
|                                                                                              /-> [ Charlie Target Group ] |
| [ blog.example.com ] ----------> ALB (us-west-2) ----> [ blog.example.com ] ----------------|                             |
| (Latency-based, us-west-2)                                                                   \-> [ Delta Target Group ]   |
+---------------------------------------------------------------------------------------------------------------------------+
```

## Module-Specific Notes

### Endpoint

#### ALB Target Group Healthchecks
The default healthchecks associated with the service module are just checking the health of Kubernetes itself on each instance.  This is totally fine for cases where only one cluster is attached, or when all attached clusters are guaranteed to be running a copy of that service.  If at any time one or more cluster in the Target Group exists without running a copy of that service (say when a cluster is first deployed), all requests the ALB routes to it will fail.  ALB Target Group Healthchecks can be configured for each service so that instances will only be routable if they are able to handle requests for the service, but there's a small catch.

## Restrictions, Quirks, and Assumptions
* ALB Target Group healthchecks are currently not able to pass `Host` headers, and therefore cannot be used with `Ingress`-based services in Kubernetes.  They can be worked in with `NodePort` services, however I stripped out that added complexity for now.
* `ALB`'s do not currently support TLS passthrough, so the Control Plane API endpoint cannot be fronted by the same `ALB` as all other traffic.  An `NLB` would be a better solution if cost weren't a consideration, however I've instead opted to just point a DNS records at control plane instances instead.  The biggest pain point is that `terraform` must be re-apply'd if any of the control plane nodes get replaced, which felt like an acceptable trade-off for $15 a month considering the fairly limited impact of that endpoint (used for local `kubectl` commands and when a worker joins the cluster).

