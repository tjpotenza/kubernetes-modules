# `tjpotenza/kubernetes-modules`
A few modules, scripts, and tools I use for managing personal Kubernetes clusters. Currently built around Rancher's [k3s](https://k3s.io/).

*Disclaimer: This project isn't \*really\* meant for consumption or serious use outside of my own; it's more of a public sandbox, a portfolio piece, and an opportunity to experiment with and share a bunch of cool pattern I've encountered.  I make a bunch of choices and compromises that are specific to my use-cases, and make breaking changes regularly.*

## Why?
To provide a platform for several of my hobby projects, while also being one of those hobby projects itself.  I also wanted the opportunity to play around with larger scale multi-cluster orchestration patterns while keeping my personal AWS spend at somewhat "hobby project" levels, so _many_ of the design choices here are made with the mindset of being able to rapidly provision, experiment with, and tear down clusters of all sizes.

## Design Principles
* For every module that depends on external resources, those resources can **either** be looked up with human-readable values or passed in explicitly by ID.  Resources being created in well known or stable environments (ie cluster in long-lived VPCs, or `node_groups` for long-lived clusters) should be able to leverage convenient lookups, while projects that create entire clusters should be able to string the outputs and inputs together in a way that allows Terraform to properly order and relate the components to each other.
* Clusters deployed with these modules independent from any external orchestration dependencies, such as Jenkins or Vault; all bootstrapping required for general use of a cluster should be environment agnostic and managed using tooling included within the cluster and native cloud-provider utilities, such as tag lookups.
* These modules should be "pure" and best-practice-y Terraform modules, and shouldn't require any weird commands or `-target`ing.  A `terraform apply` should be all it takes to fully deploy one of these clusters from any state, even from a cold start.  (Recycling instances in an `ASG` after changing a `Launch Template` is the one exception here; I'm still deciding what approach is the most "in the spirit" of this project, be that `palantir/bouncer`, something more home-grown, or nothing at all)


## Noteable Characteristics & Common Patterns Implemented (So Far)
* Control Planes instances are "stacked", running both the Kubernetes Control Plane and `etcd`.
* During general operation, both Control Plane and Node instances will automatically join their cluster on startup, and will gracefully drain, cordon, then remove themselves from the cluster on shutdown.
* During general operation, the `etcd` members running on Control Plane instances will also join their cluster on startup and gracefully remove themselves on shutdown.
* A cluster can invoke the `Control Plane` and `Node Group` modules several times, allowing for a heterogenous deployment of instances, versions, or settings.
* Nodes have the `topology.kubernetes.io/zone` label set to their Availability Zone (ie `us-east-1a`), so stateful services that require a EBS Volumes (ie `prometheus`) can use `nodeSelectors` to be placed consistently within the same AZ as their EBS Volumes, and a `node_group` can be created with `subnet_filters = { availability-zone: ["us-east-1a"] }` to ensure there's always instances in those Availability Zones.

## Overview

### General Structure

There are two types of module in this repo: several that directly correspond to components of a Kubernetes clusters, and a few Quailty-of-Life modules for related resources.  A full example of these modules being exercised to create a cluster can be found under [example/](./example/).  The rough breakdown of these modules is as follows:

Kubernetes-specific modules:
* The `cluster_baseline` module creates most of the auxiliary resources for a cluster, such as target groups, IAM roles, security groups, and ALB listener rules.
* The `control_plane` module creates a group of control plane instances.  Many different control plane instance groups can be associated with the same cluster.
* The `node_group` module creates a group of nodes for running the majority of the workload.  Many different control plane instance groups can be associated with the same cluster.
* The `shared_endpoint` module creates a DNS record and ALB Listener Rule for a service that can route requests across one or more clusters.

Quality-of-Life modules:
* The `certificate` module creates an ACM certificate and validates it with DNS-based validation.
* The `shared_alb` module manages an ALB and just the resources that'd be needed for a fairly typical use-case (namely listeners on ports `80`/`443` and security groups allowing connectivity into the ALB and between the ALB and any downstream instances).

Dependent resources discussed within that are not currently managed by modules in this repo are:
* Any DNS Zones themselves.
* A Route53 alias record of format `*.{region}.{dns_zone}` pointed to the Shared ALB(s), if using the automatic ingress setup.

### Opinionated Networking Setup

#### Automatic Ingress
These modules support automatically creating ingress routes for each cluster of format `{service}--{cluster}.{region}.{dns_zone}`.  These are meant more for developing/validating service and to establish a spec for internal cross-cluster communication, such as for telemetry and log aggregation.  The naming structure was chosen to be as re-useable as possible, considering the single-level restriction on DNS and Certificate wildcards.  The double-hyphen was chosen as a delimiter between service and cluster that _shouldn't_ ever come up in regular usage, and should be safe from accidental collisions.

**Prerequisites**: In the general case, a wildcard DNS record per-region (such as `*.{region}.{dns_zone}`) must exist and be pointed to an `ALB` within the region ([`shared_alb`]()).  That `ALB` should have an attached certificate whose SANs include `*.{region}.{dns_zone}` ([`certificate`]()).  Each cluster gets a rule on the listener for port `443` that matches `*--{cluster}.{region}.{dns_zone}` and routes to a target group that contains that cluster's instances ([`cluster_baseline`]()).

The basic overview of what resources are used in this setup and whether they are managed as part of shared, cluster-specific, or endpoint-specific config is outlined in the diagrams below.

#### Cluster Endpoints (Automatic `Ingress`)
```
+--------------------------------+----------------------+-----------------------------------------+-----------------------------+--------------------------+
|  Route 53 (Shared)             | ALB (Shared)         | ALB Listeners (Per Cluster)             | Target Group (Per Cluster)  | Instances (Per Cluster)  |
+--------------------------------+----------------------+-----------------------------------------+-----------------------------+--------------------------+
|                                                     /-> [ *--alpha.us-east-1.example.com ] -----> [ Alpha Target Group ] -----> [ Alpha Instances ]      |
| [ *.us-east-1.example.com ] ---> ALB (us-east-1) --|                                                                                                     |
|                                                     \-> [ *--bravo.us-east-1.example.com ] -----> [ Bravo Target Group ] -----> [ Bravo Instances ]      |
|                                                                                                                                                          |
|                                                     /-> [ *--charlie.us-west-2.example.com ] ---> [ Charlie Target Group ] ---> [ Charlie Instances ]    |
| [ *.us-west-2.example.com ] ---> ALB (us-west-2) --|                                                                                                     |
|                                                     \-> [ *--delta.us-west-2.example.com ] -----> [ Delta Target Group ] -----> [ Delta Instances ]      |
+-------------------------------------------------------------------------------------------------------------------------------+--------------------------+
```

#### Shared Endpoints (`Ingress`-Based)
```
+--------------------------------+---------------------+-----------------------------------------+-----------------------------+--------------------------+
| Route 53 (Per Endpoint)        | ALB (Shared)        | ALB Listeners (Per Endpoint)            | Target Group (Per Cluster)  | Instances (Per Cluster)  |
+--------------------------------+---------------------+-----------------------------------------+-----------------------------+--------------------------+
|                                                                                              /-> [ Alpha Target Group ] -----> [ Alpha Instances ]      |
| [ blog.example.com ] ----------> ALB (us-east-1) ----> [ blog.example.com ] ----------------|                                                           |
| (Latency-based, us-east-1)                                                                   \-> [ Bravo Target Group ] -----> [ Bravo Instances ]      |
|                                                                                                                                                         |
|                                                                                              /-> [ Charlie Target Group ] ---> [ Charlie Instances ]    |
| [ blog.example.com ] ----------> ALB (us-west-2) ----> [ blog.example.com ] ----------------|                                                           |
| (Latency-based, us-west-2)                                                                   \-> [ Delta Target Group ] -----> [ Delta Instances ]      |
+------------------------------------------------------------------------------------------------------------------------------+--------------------------+
```

#### Shared Endpoints (`NodePort`-Based)
```
+--------------------------------+---------------------+-----------------------------------------+-----------------------------+--------------------------+
| Route 53 (Per Endpoint)        | ALB (Shared)        | ALB Listeners (Per Endpoint)            | Target Group (Per Endpoint) | Instances (Per Cluster)  |
+--------------------------------+---------------------+-----------------------------------------+-----------------------------+--------------------------+
|                                                                                                                            /-> [ Alpha Instances ]      |
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

## Roadmap / Planned Changes / Wish List

A few of the ideas I've been mulling over, but haven't had the opportunity to implement are:
* Add EC2 instance lifecycle hooks to both `control_plane` and `node_group`.
* Add support for other distributions of Kubernetes (Vanilla, EKS, etc).
* Add certificate-based authentication and TLS for `etcd`.
* Add a bit more durability and retry logic into the auto-join and auto-leave logic.
* Move a few more of the manifests and Helm Charts I use within K8S into this repo.
* Swap out the slightly-janky `worker-bootstrapper` tool for something that features better access controls against the cluster tokens/certificate.  Current plan's a single-pod Vault deployment with no persistence that at each startup fully initializes itself, stores relevant secrets, and configures an `aws` auth backend to allow instances within the cluster to authenticate with an IAM role and retrieve the `node-token` / `ServiceAccount` credentials.

## Restrictions, Quirks, and Assumptions

`ALB`'s do not currently support TLS passthrough, so the Control Plane API endpoint cannot be fronted by the same `ALB` as all other traffic.  I cheat my way around paying for an `NLB` by implementing discount-service-discovery with `aws ec2 describe-instances` and [looking up Control Plane instance IPs when needed]().

In my limited testing, it seems Kubernetes (or at least `k3s`) only uses the given control plane address for initially discovering a cluster, and doesn't seem to mind if that particular address becomes unavailable subsequently.  Given that, I've seen success just having this discovery step toss an entry into `/etc/hosts`, and appending an invocation of it onto each node's `systemd` unit as a `ExecStartPre` directive.  Anywhere else that depends on finding the Control Plane (such as the [graceful-shutdown]() tooling) will refresh that lookup with retries, assuming it'll get a hit _eventually_.

That's all a kind of ugly hack, however has been _good enough_ for most of my use-cases, and definitely worth $15/month to me.  If I stumble upon any bigger vulnerabilities or weaknesses to it I'll revisit the pattern or consider replacing it (either with an `NLB` or maybe "real" service-discovery tech like Consul.)
