variable "aws_access_key" {
  description = "Personal AWS account access key. Placeholder only - set in terraform.tfvars (gitignored), never commit a real value."
  type        = string
  sensitive   = true
  default     = "REPLACE_WITH_ACCESS_KEY"
}

variable "aws_secret_key" {
  description = "Personal AWS account secret key. Placeholder only - set in terraform.tfvars (gitignored), never commit a real value."
  type        = string
  sensitive   = true
  default     = "REPLACE_WITH_SECRET_KEY"
}

variable "aws_region" {
  description = "Region for the jump VM. Pick per-engagement for the rotation model."
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "Deliberately small - this box only relays traffic, no heavy compute. t4g.micro (Graviton/arm64) is cheaper if you don't mind switching the AMI filter to arm64; t3.micro is the safer x86_64 default."
  type        = string
  default     = "t3.micro"
}

variable "allowed_admin_cidr" {
  description = "CIDR allowed to reach SSH (22) and the WireGuard port on the jump VM - your home/thor's public IP, /32. Placeholder - real IPs do not belong in version control."
  type        = string
  default     = "REPLACE_WITH_YOUR_IP/32"
}

variable "ssh_public_key" {
  description = "Public key installed on the jump VM's admin user, for direct SSH access (separate from the WireGuard tunnel itself, useful for troubleshooting the box directly). Placeholder."
  type        = string
  default     = "REPLACE_WITH_SSH_PUBLIC_KEY"
}

variable "wg_port" {
  description = "WireGuard UDP listen port on the jump VM."
  type        = number
  default     = 51820
}

variable "wg_server_tunnel_ip" {
  description = "WireGuard interface address on the jump VM (server side of the point-to-point tunnel)."
  type        = string
  default     = "10.66.66.1/24"
}

variable "wg_client_tunnel_ip" {
  description = "WireGuard interface address (client side of the tunnel). Written into the server's peer config as the allowed address for the client."
  type        = string
  default     = "10.66.66.2/32"
}
