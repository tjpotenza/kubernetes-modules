# `tjpotenza/kubernetes-modules`

A few modules, scripts, and tools I use for managing personal Kubernetes clusters built around Rancher's [k3s](https://k3s.io/).

*Disclaimer: This project isn't \*really\* meant for consumption or serious use outside of my own; it's more a public sandbox, a portfolio piece, and an opportunity to experiment with and record a bunch of cool pattern I've encountered.  I make a bunch of choices and compromises that are specific to my use-cases, and regularly make breaking changes.*

*Disclaimer #2: These modules and these docs are not complete, and very well may never be.*

## Why?

To provide a platform for several of my hobby projects, while also being one of those hobby projects itself.  I also wanted the opportunity to play around with larger scale multi-cluster orchestration patterns while keeping my personal AWS bill at somewhat "hobby project" levels, so _many_ of the design choices here are made with cost-effectively operating lots of short-lived and small clusters in particular.

## Overview

### General Structure

The super high-level summary of how these pieces fit together is as follows:
* The `control_plane` module creates a baseline cluster and a handful of auxiliary resources.
* The `workers` module creates a group of nodes that can be attached to an existing `control_plane` cluster.
* The `shared_endpoint` module creates a DNS record and ALB Listener Rule for a service that can be running on one or more cluster.

Not currently managed in this repo are:
* The DNS Zones.
* The Shared ALB(s) per-region, and the security group that allows traffic to/from them.
* A Route53 alias record of format `*.{region}.{dns_zone}` pointed to the Shared ALB(s), if using the automatic ingress setup.

#### Automatic Ingress

Cluster-specific ingresses can be automatically configured.  In the general case, a wildcard DNS record per-region (such as `*.{region}.{dns_zone}`) would be created and pointed to a regional ALB.  Each `control_plane` module invocation can manage ALB listener rules with `var.external.ingress` and `var.internal.ingress` to create rules that route requests to the cluster with hostnames of format `*--{cluster}.{region}.{dns_zone}`.  Shorter addresses that can distribute requests among one or more clusters can be created with the `shared_endpoint` module.

The basic overview of what resources are used in this setup and whether they are managed as part of shared, cluster-specific, or endpoint-specific config is outlined in the diagrams below.

#### Cluster Endpoints (Automatic `Ingress`)
```
+--------------------------------+----------------------+-----------------------------------------+-----------------------------+--------------------------+
|  Route 53 (Shared)             | ALB (Shared)         | ALB Listeners (Per Cluster)             | Target Group (Per Cluster)  | Instances (Per Cluster)  |
+--------------------------------+----------------------+-----------------------------------------+-----------------------------+--------------------------+
|                                                     /-> [ *--alpha.us-east-1.example.com ] -----> [ Alpha Target Group ] -----> [ Alpha Instance ]       |
| [ *.us-east-1.example.com ] ---> ALB (us-east-1) --|                                                                          |                          |
|                                                     \-> [ *--bravo.us-east-1.example.com ] -----> [ Bravo Target Group ] -----> [ Bravo Instances ]      |
|                                                                                                                               |                          |
|                                                     /-> [ *--charlie.us-west-2.example.com ] ---> [ Charlie Target Group ] ---> [ Charlie Instances ]    |
| [ *.us-west-2.example.com ] ---> ALB (us-west-2) --|                                                                          |                          |
|                                                     \-> [ *--delta.us-west-2.example.com ] -----> [ Delta Target Group ] -----> [ Delta Instances ]      |
+-------------------------------------------------------------------------------------------------------------------------------+--------------------------+
```

#### Shared Endpoints (`Ingress`-Based)
```
+--------------------------------+---------------------+-----------------------------------------+-----------------------------+--------------------------+
| Route 53 (Per Endpoint)        | ALB (Shared)        | ALB Listeners (Per Endpoint)            | Target Group (Per Cluster)  | Instances (Per Cluster)  |
+--------------------------------+---------------------+-----------------------------------------+-----------------------------+--------------------------+
|                                                                                              /-> [ Alpha Target Group ] -----> [ Alpha Instance ]       |
| [ blog.example.com ] ----------> ALB (us-east-1) ----> [ blog.example.com ] ----------------|                                |                          |
| (Latency-based, us-east-1)                                                                   \-> [ Bravo Target Group ] -----> [ Bravo Instances ]      |
|                                                                                                                              |                          |
|                                                                                              /-> [ Charlie Target Group ] ---> [ Charlie Instances ]    |
| [ blog.example.com ] ----------> ALB (us-west-2) ----> [ blog.example.com ] ----------------|                                |                          |
| (Latency-based, us-west-2)                                                                   \-> [ Delta Target Group ] -----> [ Delta Instances ]      |
+------------------------------------------------------------------------------------------------------------------------------+--------------------------+
```

#### Shared Endpoints (`NodePort`-Based)
```
+--------------------------------+---------------------+-----------------------------------------+-----------------------------+--------------------------+
| Route 53 (Per Endpoint)        | ALB (Shared)        | ALB Listeners (Per Endpoint)            | Target Group (Per Endpoint) | Instances (Per Cluster)  |
+--------------------------------+---------------------+-----------------------------------------+-----------------------------+--------------------------+
|                                                                                                                            /-> [ Alpha Instance ]       |
| [ blog.example.com ] ----------> ALB (us-east-1) ----> [ blog.example.com ] -------------------> [ Blog Target Group ] ---|                             |
| (Latency-based, us-east-1)                                                                                                 \-> [ Bravo Instances ]      |
|                                                                                                                                                         |
|                                                                                                                            /-> [ Charlie Instances ]    |
| [ blog.example.com ] ----------> ALB (us-west-2) ----> [ blog.example.com ] -------------------> [ Blog Target Group ] ---|                             |
| (Latency-based, us-west-2)                                                                                                 \-> [ Delta Instances ]      |
+------------------------------------------------------------------------------------------------------------------------------+--------------------------+
```

## Module-Specific Notes

### Endpoint

The `shared_endpoint` module creates a regional DNS record for a given service, and creates a rule for it on the ALB behind that DNS record.  That endpoint can be associated with the clusters behind it in two distinct manners; one that works well for `Ingress`-based services and one that works well for `NodePort`-based services.

#### `Ingress`-Based

This module can accept a map of `Target Groups` that will _all_ be attached to the `Listener Rule` and can be individually weighted.  This setup allows for more readable Terraform in my opinion, and easily allows for different clusters within a region to receive different proportions of traffic.  It does _not_ allow for the ALB to automatically remove a cluster from rotation based on healthchecks, however: an ALB will route requests among all `Target Groups` attached to the corresponding `Listener Rule`, regardless if any nodes in that cluster are passing their healthchecks.  Additional, `Target Group` healthchecks cannot currently send a `Host` header, so they are not particularly useful with `Ingress`-based services.

#### `NodePort`-Based

As mentioned above, `Target Group` healthchecks cannot currently send `Host` headers.  This module can be configured with `var.shared_target_group` to create and attach a service-specific `Target Group` to the `Listener Rule`, which can be configured to properly evaluate a `NodePort`-based service's health.  That `Target Group` can be fed into the `var.target_group_arns` of a `control_plane` and `workers` modules to attach the nodes for all clusters.

## Restrictions, Quirks, and Assumptions
* `ALB`'s do not currently support TLS passthrough, so the Control Plane API endpoint cannot be fronted by the same `ALB` as all other traffic.  An `NLB` would be a better solution if cost weren't a consideration, however I've instead opted to just point a DNS records at control plane instances instead.  The biggest pain point is that `terraform` must be re-apply'd if any of the control plane nodes get replaced, which felt like an acceptable trade-off for $15 a month considering the fairly limited impact of that endpoint (used for local `kubectl` commands and when a worker joins the cluster).
* The default healthchecks associated with these `Target Groups` are checking the health of Kubernetes itself on each instance.  This is typically fine for cases where only one cluster is attached, or when all attached clusters are guaranteed to be running a healthy copy of that service.  If at any time one or more cluster in the Target Group exists without running a copy of that service (say when a cluster is first deployed), all requests the ALB routes to it will fail.  A `NodePort`-based service as described above can/should be used for use-cases where a service endpoint should be able to failover between clusters within a region.
