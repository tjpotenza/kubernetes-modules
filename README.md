# `tjpotenza/kubernetes-modules`
A few modules, scripts, and tools I use for managing personal Kubernetes clusters. Currently built around Rancher's [k3s](https://k3s.io/).

*Disclaimer: This project isn't \*really\* meant for consumption or serious use outside of my own; it's more of a public sandbox, a portfolio piece, and an opportunity to experiment with and share a bunch of cool pattern I've encountered.  I make a bunch of choices and compromises that are specific to my use-cases, and make breaking changes regularly.*

## Why?
To provide a platform for several of my hobby projects, while also being one of those hobby projects itself.  I also wanted the opportunity to play around with larger scale multi-cluster orchestration patterns while keeping my personal AWS spend at somewhat "hobby project" levels, so _many_ of the design choices here are made with the mindset of being able to rapidly provision, experiment with, and tear down clusters of all sizes.

## Design Principles
* For every module that depends on external resources, those resources can **either** be looked up with human-readable values or passed in explicitly by ID.  Resources being created in well known or stable environments (ie cluster in long-lived VPCs, or `node_groups` for long-lived clusters) should be able to leverage convenient lookups, while projects that create entire clusters should be able to string the outputs and inputs together in a way that allows Terraform to properly order and relate the components to each other.
* Clusters deployed with these modules independent from any external orchestration dependencies, such as Jenkins or Vault; all bootstrapping required for general use of a cluster should be environment agnostic and managed using tooling included within the cluster and native cloud-provider utilities, such as tag lookups.
* There shouldn't be any out-of-band configuration steps required, or `-target`ing for first-time deployment; a `terraform apply` should be all it takes to fully update or deploy one of these clusters from any state, even from a cold start.  (Recycling instances in an `ASG` after changing a `Launch Template` is the one exception here; I'm still deciding what approach is the most "in the spirit" of this project, be that implementing something like `palantir/bouncer`, something more home-grown, or nothing at all)

## Noteable Characteristics & Common Patterns Implemented (So Far)
* Control Planes instances are "stacked", running both the Kubernetes Control Plane and `etcd`.
* During general operation, both Control Plane and Node instances will automatically join their cluster on startup, and will gracefully drain, cordon, then remove themselves from the cluster on shutdown.
* During general operation, the `etcd` members running on Control Plane instances will also join their cluster on startup and gracefully remove themselves on shutdown.
* A cluster can invoke the `Control Plane` and `Node Group` modules several times, allowing for a heterogenous deployment of instances, versions, or settings.
* Nodes have the `topology.kubernetes.io/zone` label set to their Availability Zone (ie `us-east-1a`), so stateful services that require EBS Volumes (ie `prometheus`) can use `nodeSelectors` to be placed consistently within the same AZ as their EBS Volumes, and dedicated a `node_group` can be created with `subnet_filters = { availability-zone: ["us-east-1a"] }` to ensure there's always instances in those Availability Zones.

## Overview

### General Structure

_Note: There's a lot of variables, locals, and userdata bits shared between these modules, so I've symlinked common files where applicable.  Anywhere there is a symlink, the source of truth is the copy within [`control_plane`](./control_plane)_

There are two types of module in this repo: several that directly correspond to components of a Kubernetes clusters, and a few Quailty-of-Life modules for related resources.  The rough breakdown of these modules is as follows:

**Kubernetes-specific modules:**
* The [`cluster_baseline`](./cluster_baseline) module creates most of the auxiliary resources for a cluster, such as target groups, IAM roles, security groups, and ALB listener rules.
* The [`control_plane`](./control_plane) module creates a group of control plane instances.  Many different control plane instance groups can be associated with the same cluster.
* The [`node_group`](./node_group) module creates a group of nodes for running the majority of the workload.  Many different node instance groups can be associated with the same cluster.
* The [`shared_endpoint`](./shared_endpoint) module creates a DNS record and ALB Listener Rule for a service that can route requests across one or more clusters.

**Quality-of-Life modules:**
* The [`certificate`](./certificate) module creates an ACM certificate and validates it with DNS-based validation.
* The [`shared_alb`](./shared_alb) module manages an ALB and just the resources that'd be needed for a fairly typical use-case (namely listeners on ports `80`/`443` and security groups allowing connectivity into the ALB and between the ALB and any downstream instances).

**Dependent resources discussed within that are not currently managed by modules in this repo are:**
* Any DNS Zones themselves.
* A Route53 alias record of format `*.{region}.{dns_zone}` pointed to the Shared ALB(s), if using the automatic ingress setup.
* The Key Pairs needed for SSHing onto the instances.

To offer a rough diagram of the core resources managed by these modules and how they interact in a simple single-cluster deployment:
```
                                                                                                                                    ┌───────────────────────────────────┐
                                                                                                                                    │ control_plane                     │
                                                                                                                                    │                                   │
                                                                                                                                    │  ┌─────────────────────────────┐  │
                                                                                                                                    │  │ Autoscaling Group           │  │
                                                                                                                                    │  │┌──────────────────────────┐ │  │
                                                                                                                                 ┌──┼──┼▶ Instance (Control Plane) │ │  │
                                                                                                                                 │  │  │└──────────────────────────┘ │  │
                                                                                                                                 │  │  │┌──────────────────────────┐ │  │
┌──────────────────────────────────┐     ┌──────────────────────────────────┐     ┌─────────────────────────────────────────┐    ├──┼──┼▶ Instance (Control Plane) │ │  │
│ shared_endpoint                  │     │ shared_alb                       │     │ cluster_baseline                        │    │  │  │└──────────────────────────┘ │  │
│                                  │     │                                  │     │                                         │    │  │  │┌──────────────────────────┐ │  │
│ ┌──────────────────────────────┐ │     │ ┌──────────────────────────────┐ │     │  ┌───────────────────────────────────┐  │    ├──┼──┼▶ Instance (Control Plane) │ │  │
│ │       Route 53 Record        │ │     │ │      ALB Listener (80)       │ │     │  │    IAM Role + Instance Profile    ├──┼────┤  │  │└──────────────────────────┘ │  │
│ │     {service}.{dns_zone}     │ │     │ └──────────────┬───────────────┘ │     │  └───────────────────────────────────┘  │    │  │  └─────────────────────────────┘  │
│ └──────────────┬───────────────┘ │     │ ┌──────────────▼───────────────┐ │     │  ┌───────────────────────────────────┐  │    │  └───────────────────────────────────┘
│ ┌──────────────▼───────────────┐ │┌─┬──┼─▶      ALB Listener (443)      ├─┼─────┼──▶           Target Group            ├──┼────┤
│ │      ALB Listener Rule       ├─┼┘ │  │ └──────────────────────────────┘ │     │  └───────────────────────────────────┘  │    │  ┌───────────────────────────────────┐
│ │     {service}.{dns_zone}     │ │  │  │ ┌──────────────────────────────┐ │     │  ┌───────────────────────────────────┐  │    │  │ node_group (main)                 │
│ └──────────────────────────────┘ │  │  │ │ Security Groups (Downstream) ├─┼─────┼──▶          Security Groups          ├──┼────┤  │                                   │
└──────────────────────────────────┘  │  │ └──────────────────────────────┘ │     │  └───────────────────────────────────┘  │    │  │  ┌─────────────────────────────┐  │
                                      │  │ ┌──────────────────────────────┐ │     │  ┌───────────────────────────────────┐  │    │  │  │ Autoscaling Group           │  │
                                      │  │ │  Security Groups (Upstream)  │ │     │  │         ALB Listener Rule         │  │    │  │  │┌──────────────────────────┐ │  │
                                      │  │ └──────────────────────────────┘ │ ┌───┼──│ *--{cluster}.{region}.{dns_zone}  │  │    ├──┼──┼▶     Instance (Node)      │ │  │
                                      │  └──────────────────────────────────┘ │   │  └───────────────────────────────────┘  │    │  │  │└──────────────────────────┘ │  │
                                      │                                       │   └─────────────────────────────────────────┘    │  │  │┌──────────────────────────┐ │  │
                                      └───────────────────────────────────────┘                                                  ├──┼──┼▶     Instance (Node)      │ │  │
                                                                                                                                 │  │  │└──────────────────────────┘ │  │
                                                                                                                                 │  │  │┌──────────────────────────┐ │  │
                                                                                                                                 └──┼──┼▶     Instance (Node)      │ │  │
                                                                                                                                    │  │└──────────────────────────┘ │  │
                                                                                                                                    │  └─────────────────────────────┘  │
                                                                                                                                    └───────────────────────────────────┘
```

### Opinionated Networking Setup

#### Automatic Ingress
These modules support automatically creating ingress routes for each cluster of format `{service}--{cluster}.{region}.{dns_zone}`.  These are meant more for developing/validating service and to establish a consistent spec for internal cross-cluster communication, such as for telemetry and log aggregation.  The naming structure was chosen to be as re-useable as possible, considering the single-level restriction on DNS and Certificate wildcards.  The double-hyphen was chosen as a delimiter between service and cluster that _shouldn't_ ever come up in regular usage, and should be safe from accidental collisions.

**Prerequisites**: In the general case, a wildcard DNS record per-region (such as `*.{region}.{dns_zone}`) must exist and be pointed to an ALB within the region ([`shared_alb`](./shared_alb)).  That ALB should have an attached certificate whose SANs include `*.{region}.{dns_zone}` ([`certificate`](./certificate)).  Each cluster gets a rule on the listener for port `443` that matches `*--{cluster}.{region}.{dns_zone}` and routes to a target group that contains that cluster's instances ([`cluster_baseline`](./cluster_baseline)).

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

### Shared Endpoints

The `shared_endpoint` module is designed to create a shorter more permanent DNS record for a particular service that is running in one or more clusters.

It creates a Latency-based DNS record for that endpoint in the region, pointed to an ALB Listener Rule that will route requests across one or more clusters within the region.  That endpoint can be associated with the clusters behind it in two distinct manners; one that works well for `Ingress`-based services and one that works well for `NodePort`-based services.

#### `Ingress`-Based

The `shared_endpoint` module can accept a map of `Target Groups` that will _all_ be attached to the `Listener Rule` and can be individually weighted.  This setup allows for more readable Terraform in my opinion, and easily allows for different clusters within a region to receive different proportions of traffic.  It does _not_ allow for the ALB to automatically remove a cluster from rotation based on healthchecks, however: even if all members of a Target Group are unavailable, the ALB will not redistribute that Target Group's share of the traffic and instead will allow those requests to continually fail.  This also means that a cluster's Target Group can not be associated with a service until that service is deployed to the cluster, otherwise that share of traffic would fail.

_(Target Group healthchecks can also not currently pass a `Host` header, so they are not able to evaluate the health of a particular service when routing to an `Ingress`-based service; just the health of the entire instance instead typically)_

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

#### `NodePort`-Based

The `shared_endpoint` module _can also_ be configured "in reverse", where a service-specific Target Group is created for passing into `cluster_baseline`, `control_plane`, and `node_group` invocations to have those clusters' instances directly attached.

There's a few distinct pros and cons to having all clusters' instance co-mingled in the same Target Group; it means that with Target Group Healthchecks enabled, a cluster that has entirely failed _will automatically stop receiving traffic altogether, shifting the remainder onto the remaining clusters entirely_.

This pattern works best when configured with `NodePort`-based services, so that the Target Group Healthchecks can be used to evaluate _just_ that service's health.  When deployed in this fashion, traffic can be routed between clusters on a per-service basis.  Additionally, a cluster can be added to a service's `shared_endpoint` before that service is fully deployed there; traffic will not be routed to that cluster until the service reports as available.

_(The biggest consideration to be mindful of with this architecture's probably the cascading overload scenario: if one cluster is over capacity and fails, then its share of traffic is redistributed amongst the remaining clusters.  If the remaining clusters were all themselves nearing capacity, a cycle may form where clusters keep failing and redistributing their load over an increasingly small pool of instances until they're all unavailable.  Auto-scaling, self-healing, and the observability to avoid running this close to capacity are the main defenses that come to my mind against this particular scenario.)_

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

### Accessing the Cluster

See the helper script at [`scripts/generate_kubeconfig.sh`](./scripts/generate_kubeconfig.sh) for more details on the current mechanism for granting local access to the cluster.  At a high level, it depends on local SSH access being available to the Control Plane instances, and local IAM permissions for _at least_ `ec2:DescribeInstances` to discover the Control Plane. A sample invocation would be:

```bash
REGION="us-east-1" ./scripts/generate_kubeconfig.sh <cluster name>
```

## Roadmap / Planned Changes / Wish List

A few of the ideas I've been mulling over, but haven't had the opportunity to implement are:
* Add EC2 instance lifecycle hooks to both `control_plane` and `node_group`.
* Add support for other distributions of Kubernetes (Vanilla, EKS, etc).
* Add certificate-based authentication and TLS for `etcd`.
* Add a bit more durability and retry logic into the auto-join and auto-leave logic.
* Move a few more of the manifests and Helm Charts I use within K8S into this repo.
* Swap out the slightly-janky `worker-bootstrapper` tool for something that features better access controls against the cluster tokens/certificate.  Current plan's a single-pod Vault deployment with no persistence that at each startup fully initializes itself, stores relevant secrets, and configures an `aws` auth backend to allow instances within the cluster to authenticate with an IAM role and retrieve the `node-token` / `ServiceAccount` credentials.
* Look into implementing other RBAC identity providers, such as OIDC.
* Add `terratest` or some other testing framework to help catch regressions and breaking changes.

## Restrictions, Quirks, and Assumptions

`ALB`'s do not currently support TLS passthrough, so the Control Plane API endpoint cannot be fronted by the same `ALB` as all other traffic.  I cheat my way around paying for an `NLB` by implementing a discount form of service discovery with `aws ec2 describe-instances` and [looking up Control Plane instance IPs when needed](./node_group/user_data/k3s/discover-control-plane.sh).

In my limited testing, it seems Kubernetes (or at least `k3s`) only uses the given control plane address for initially discovering a cluster, and doesn't seem to mind if that particular address becomes unavailable subsequently.  Given that, I've seen success by having this discovery step update an entry in `/etc/hosts`, and appending an invocation of it onto each node's `systemd` unit as a `ExecStartPre` directive.  Anywhere else that depends on finding the Control Plane (such as the [graceful-shutdown](./control_plane/user_data/k3s/graceful-shutdown.sh) tooling) can refresh that lookup with retries, assuming it'll get a hit _eventually_.

That's all a kind of ugly hack, however has been _good enough_ for most of my use-cases, and definitely worth $15/month to me.  If I stumble upon any bigger vulnerabilities or weaknesses to it I'll revisit the pattern or consider replacing it (either with an `NLB` or maybe "real" service-discovery tech like Consul.)
