# =============================================================================
# VPC MODULE - OUTPUTS
# =============================================================================
#
# WHAT IS THIS FILE?
# ------------------
# Outputs expose values from this module so OTHER modules can use them.
#
# Think of it like a function's return value:
#   def create_vpc(...):
#       ...
#       return vpc_id, subnet_ids   # <-- These are outputs
#
# Other modules will need things like:
#   - VPC ID (to put resources inside the VPC)
#   - Subnet IDs (to place containers, databases in subnets)
#
# =============================================================================


# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id

  # HOW TO USE THIS OUTPUT
  # ----------------------
  # When another module uses this VPC module:
  #
  #   module "vpc" {
  #     source = "../modules/vpc"
  #     ...
  #   }
  #
  # They can reference this output as:
  #   module.vpc.vpc_id
}


output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}


# -----------------------------------------------------------------------------
# SUBNETS
# -----------------------------------------------------------------------------

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id

  # SPLAT EXPRESSION: [*]
  # ---------------------
  # aws_subnet.public is a LIST of subnets (because we used count).
  # aws_subnet.public[*].id gets the .id from EACH subnet.
  #
  # Result: ["subnet-abc123", "subnet-def456"]
  #
  # This is shorthand for:
  #   [for subnet in aws_subnet.public : subnet.id]
}


output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}


output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}


output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}


# -----------------------------------------------------------------------------
# NAT GATEWAY
# -----------------------------------------------------------------------------

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}


output "nat_public_ips" {
  description = "List of NAT Gateway public IPs"
  value       = aws_eip.nat[*].public_ip

  # WHY WOULD YOU NEED THIS?
  # ------------------------
  # If you call an external API that whitelists IPs,
  # you need to give them your NAT Gateway IPs.
  # All traffic from private subnets appears to come
  # from the NAT Gateway's public IP.
}


# -----------------------------------------------------------------------------
# AVAILABILITY ZONES
# -----------------------------------------------------------------------------

output "availability_zones" {
  description = "List of AZs used"
  value       = var.availability_zones
}


# -----------------------------------------------------------------------------
# INTERNET GATEWAY
# -----------------------------------------------------------------------------

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}


# =============================================================================
# HOW OTHER MODULES USE THESE OUTPUTS
# =============================================================================
#
# Example: An ECS module needs to know which subnets to use
#
#   module "vpc" {
#     source       = "../modules/vpc"
#     project_name = "gacha-platform"
#     environment  = "dev"
#   }
#
#   module "ecs" {
#     source = "../modules/ecs"
#
#     vpc_id     = module.vpc.vpc_id           # <-- Using output
#     subnet_ids = module.vpc.private_subnet_ids  # <-- Using output
#   }
#
# The ECS module doesn't need to know HOW the VPC was created.
# It just uses the outputs.
#
# This is called ENCAPSULATION - modules are self-contained.
#
