# VPC Module Overview

Quick reference for what this module creates and in what order.

---

## Files in This Module

| File | Purpose |
|------|---------|
| `variables.tf` | Input parameters (what you can customize) |
| `main.tf` | Actual AWS resources (the infrastructure) |
| `outputs.tf` | Values exposed for other modules to use |

---

## Resource Creation Order

Terraform figures out the order automatically based on dependencies, but here's the logical flow:

```
1. VPC
   └── The container for everything

2. Internet Gateway
   └── Attached to VPC, enables internet access

3. Subnets (Public & Private)
   └── Divide the VPC into network segments

4. Elastic IPs
   └── Static public IPs for NAT Gateways

5. NAT Gateways
   └── Allow private subnets to reach internet

6. Route Tables
   └── Define traffic rules

7. Route Table Associations
   └── Connect subnets to their route tables
```

---

## Resources at a Glance

### 1. VPC (`aws_vpc.main`)
```
What:   Virtual Private Cloud - your private network in AWS
CIDR:   10.0.0.0/16 (65,536 IPs)
Why:    Everything else goes inside this
```

### 2. Internet Gateway (`aws_internet_gateway.main`)
```
What:   Connection between VPC and public internet
Why:    Without this, nothing can reach the internet
```

### 3. Public Subnets (`aws_subnet.public`)
```
What:   Network segments WITH internet access
CIDRs:  10.0.1.0/24, 10.0.2.0/24
AZs:    One subnet per availability zone
Used:   Load balancers, NAT gateways
```

### 4. Private Subnets (`aws_subnet.private`)
```
What:   Network segments WITHOUT direct internet access
CIDRs:  10.0.10.0/24, 10.0.11.0/24
AZs:    One subnet per availability zone
Used:   ECS containers, databases, Lambda
```

### 5. Elastic IPs (`aws_eip.nat`)
```
What:   Static public IP addresses
Why:    NAT Gateways need a fixed public IP
Count:  1 (single NAT) or 2 (one per AZ)
```

### 6. NAT Gateways (`aws_nat_gateway.main`)
```
What:   Allows private → internet (but not internet → private)
Where:  Lives in public subnet
Why:    Private resources need to download packages, call APIs
Cost:   ~$32/month each
```

### 7. Route Tables
```
Public Route Table:
  - 0.0.0.0/0 → Internet Gateway
  - "All internet traffic goes to IGW"

Private Route Table:
  - 0.0.0.0/0 → NAT Gateway
  - "All internet traffic goes to NAT"
```

### 8. Route Table Associations
```
What:   Links subnets to route tables
Public subnets  → Public route table
Private subnets → Private route table
```

---

## Visual Summary

```
┌─────────────────────────────────────────────────────────────┐
│                         VPC                                  │
│                    (10.0.0.0/16)                            │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              INTERNET GATEWAY                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                  │
│  PUBLIC SUBNETS          │                                  │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ 10.0.1.0/24  │  │ 10.0.2.0/24  │                        │
│  │    (AZ-a)    │  │    (AZ-c)    │                        │
│  │ NAT Gateway  │  │              │                        │
│  └──────┬───────┘  └──────────────┘                        │
│         │                                                   │
│  PRIVATE SUBNETS                                           │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ 10.0.10.0/24 │  │ 10.0.11.0/24 │                        │
│  │    (AZ-a)    │  │    (AZ-c)    │                        │
│  │              │  │              │                        │
│  │  Containers  │  │  Containers  │                        │
│  │  Databases   │  │  Databases   │                        │
│  └──────────────┘  └──────────────┘                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `project_name` | (required) | Names all resources |
| `environment` | "dev" | dev, staging, or prod |
| `vpc_cidr` | "10.0.0.0/16" | VPC IP range |
| `availability_zones` | ["ap-northeast-1a", "ap-northeast-1c"] | Data centers |
| `enable_nat_gateway` | true | Create NAT? |
| `single_nat_gateway` | true | One NAT vs one per AZ |

---

## Key Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `vpc_id` | VPC identifier | Almost everything |
| `public_subnet_ids` | Public subnet IDs | ALB, NAT |
| `private_subnet_ids` | Private subnet IDs | ECS, RDS, Lambda |
| `nat_public_ips` | NAT Gateway IPs | IP whitelisting |

---

## Estimated Costs

| Resource | Dev | Prod |
|----------|-----|------|
| VPC | Free | Free |
| Internet Gateway | Free | Free |
| Subnets | Free | Free |
| NAT Gateway | ~$32/mo | ~$64/mo (2x) |
| Elastic IP (in use) | Free | Free |
| **Total** | **~$32/mo** | **~$64/mo** |

*Note: Data transfer through NAT is extra (~$0.045/GB)*
