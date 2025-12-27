# =============================================================================
# VPC MODULE - VARIABLES (INPUTS)
# =============================================================================
#
# WHAT IS THIS FILE?
# ------------------
# This file defines the INPUTS to our VPC module. Think of it like defining
# the parameters of a function:
#
#   def create_vpc(project_name, environment, vpc_cidr):
#       ...
#
# When someone uses this module, they'll provide these values.
#
# =============================================================================


# -----------------------------------------------------------------------------
# NAMING
# -----------------------------------------------------------------------------

variable "project_name" {
  # DESCRIPTION: Explains what this variable is for (shows in docs/errors)
  description = "Name of the project - used to name all resources"

  # TYPE: What kind of data this is
  #   string = text like "gacha-platform"
  #   number = numbers like 42
  #   bool   = true or false
  #   list   = ["item1", "item2"]
  #   map    = { key = "value" }
  type = string

  # NO DEFAULT = This variable is REQUIRED
  # If you don't provide it, Terraform will ask you or error
}


variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  # DEFAULT: If no value provided, use this
  default = "dev"

  # VALIDATION: Optional rules to enforce valid values
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
  # contains(list, value) checks if value is in list
  # var.environment refers to this variable's value
}


# -----------------------------------------------------------------------------
# NETWORK CONFIGURATION
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  # WHAT IS CIDR?
  # -------------
  # CIDR (Classless Inter-Domain Routing) defines a range of IP addresses.
  #
  # Format: BASE_IP/PREFIX_LENGTH
  #
  # The PREFIX_LENGTH tells you how many IPs you have:
  #   /16 = 65,536 IPs (10.0.0.0 to 10.0.255.255)
  #   /24 = 256 IPs (10.0.0.0 to 10.0.0.255)
  #   /28 = 16 IPs
  #
  # Smaller number after / = MORE IPs
  # Bigger number after / = FEWER IPs
  #
  # For a VPC, /16 is standard - gives plenty of room for subnets.
}


variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string) # List of strings

  default = ["ap-northeast-1a", "ap-northeast-1c"]

  # WHAT ARE AVAILABILITY ZONES?
  # ----------------------------
  # An AWS region (like ap-northeast-1 / Tokyo) has multiple data centers.
  # Each data center is an "Availability Zone" (AZ).
  #
  # Tokyo has: ap-northeast-1a, ap-northeast-1c, ap-northeast-1d
  # (Note: 1b doesn't exist in Tokyo!)
  #
  # We use multiple AZs for HIGH AVAILABILITY:
  #   - If one data center has a fire/flood/power outage
  #   - Your app still runs in the other AZ
  #
  # Production systems should ALWAYS use 2+ AZs.
}


variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  # PUBLIC SUBNETS
  # --------------
  # These subnets have a route to the Internet Gateway.
  # Resources here CAN be reached from the internet.
  #
  # Used for:
  #   - Load Balancers (ALB)
  #   - NAT Gateways
  #   - Bastion hosts (SSH jump boxes)
  #
  # NOT for:
  #   - Databases (security risk!)
  #   - Application servers
}


variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]

  # PRIVATE SUBNETS
  # ---------------
  # These subnets have NO route to the Internet Gateway.
  # Resources here CANNOT be reached from the internet directly.
  #
  # They CAN reach the internet via NAT Gateway (outbound only).
  # Think of NAT Gateway as a one-way door.
  #
  # Used for:
  #   - ECS containers (our services)
  #   - RDS databases
  #   - Lambda functions
  #   - Anything valuable!
}


# -----------------------------------------------------------------------------
# NAT GATEWAY SETTINGS
# -----------------------------------------------------------------------------

variable "enable_nat_gateway" {
  description = "Create NAT gateway? Required for private subnets to reach internet."
  type        = bool
  default     = true

  # NAT GATEWAY
  # -----------
  # Allows private subnet resources to access the internet
  # (for downloading packages, calling external APIs, etc.)
  # but BLOCKS incoming connections from internet.
  #
  # COST: ~$32/month per NAT Gateway + data transfer
  #
  # For dev: Could set to false to save money, but services can't
  #          reach the internet (might break things)
  # For prod: Always true
}


variable "single_nat_gateway" {
  description = "Use one NAT for all AZs (cheaper) vs one per AZ (resilient)"
  type        = bool
  default     = true # Save money for dev

  # SINGLE NAT vs MULTIPLE NAT
  # --------------------------
  #
  # single_nat_gateway = true:
  #   - One NAT Gateway shared by all private subnets
  #   - Cheaper (~$32/month)
  #   - If that NAT fails, ALL private subnets lose internet
  #   - Good for: dev, staging
  #
  # single_nat_gateway = false:
  #   - One NAT Gateway per AZ
  #   - More expensive (~$64/month for 2 AZs)
  #   - If one NAT fails, only that AZ loses internet
  #   - Good for: production
}


# -----------------------------------------------------------------------------
# TAGS
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}

  # WHAT ARE TAGS?
  # --------------
  # Key-value pairs attached to resources for organization.
  #
  # Example:
  #   tags = {
  #     "Team"       = "Platform"
  #     "CostCenter" = "Gaming"
  #   }
  #
  # Used for:
  #   - Finding resources in console
  #   - Cost allocation (see spending by tag)
  #   - Automation (apply policies to tagged resources)
}
