provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# --- WireGuard keypairs, generated locally via `wg`, never sent anywhere ---
# Static trigger so this only runs once on creation, not on every apply.
# The idempotency guard in the script is defensive, in case the resource
# is ever recreated without the generated/ directory being wiped first.
resource "null_resource" "wg_keys" {
  triggers = {
    key_set = "v1"
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      mkdir -p ${path.module}/generated
      if [ ! -f ${path.module}/generated/server_private.key ]; then
        wg genkey | tee ${path.module}/generated/server_private.key | wg pubkey > ${path.module}/generated/server_public.key
      fi
      if [ ! -f ${path.module}/generated/client_private.key ]; then
        wg genkey | tee ${path.module}/generated/client_private.key | wg pubkey > ${path.module}/generated/client_public.key
      fi
      chmod 600 ${path.module}/generated/*private.key
    EOT
  }
}

data "local_file" "server_private_key" {
  filename   = "${path.module}/generated/server_private.key"
  depends_on = [null_resource.wg_keys]
}

data "local_file" "server_public_key" {
  filename   = "${path.module}/generated/server_public.key"
  depends_on = [null_resource.wg_keys]
}

data "local_file" "client_private_key" {
  filename   = "${path.module}/generated/client_private.key"
  depends_on = [null_resource.wg_keys]
}

data "local_file" "client_public_key" {
  filename   = "${path.module}/generated/client_public.key"
  depends_on = [null_resource.wg_keys]
}

# --- AMI: current Ubuntu LTS, looked up rather than hardcoded so it never goes stale ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Security group: tight, admin-only ingress, open egress (the whole point is relaying to arbitrary targets) ---
resource "aws_security_group" "proxy" {
  name_prefix = "aws-proxy-"
  description = "Admin-only SSH + WireGuard ingress, open egress for the relays actual job."

  ingress {
    description = "SSH from admin CIDR only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_admin_cidr]
  }

  ingress {
    description = "WireGuard from admin CIDR only"
    from_port   = var.wg_port
    to_port     = var.wg_port
    protocol    = "udp"
    cidr_blocks = [var.allowed_admin_cidr]
  }

  egress {
    description = "Open - this box exists to relay traffic outward"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws-proxy"
  }
}

resource "aws_key_pair" "admin" {
  key_name_prefix = "aws-proxy-"
  public_key      = var.ssh_public_key
}

# --- The jump VM itself ---
resource "aws_instance" "proxy" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.admin.key_name
  vpc_security_group_ids = [aws_security_group.proxy.id]

  user_data = templatefile("${path.module}/cloud-init.yaml.tpl", {
    server_private_key  = trimspace(data.local_file.server_private_key.content)
    client_public_key   = trimspace(data.local_file.client_public_key.content)
    wg_port             = var.wg_port
    wg_server_tunnel_ip = var.wg_server_tunnel_ip
    wg_client_tunnel_ip = var.wg_client_tunnel_ip
  })

  tags = {
    Name = "aws-proxy"
  }
}

# Stable, known address - this is what the target sees.
resource "aws_eip" "proxy" {
  instance = aws_instance.proxy.id
  domain   = "vpc"

  tags = {
    Name = "aws-proxy"
  }
}
