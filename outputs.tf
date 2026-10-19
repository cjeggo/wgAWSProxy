output "proxy_public_ip" {
  description = "This is what the target sees - the jump VM's Elastic IP."
  value       = aws_eip.proxy.public_ip
}

output "wg_server_public_key" {
  description = "Server's WireGuard public key - needed for locals's own [Peer] block."
  value       = trimspace(data.local_file.server_public_key.content)
}

output "wg_client_private_key" {
  description = "local machine's WireGuard private key - goes in [Interface] block. Sensitive - do not print/log casually."
  value       = trimspace(data.local_file.client_private_key.content)
  sensitive   = true
}

output "wg_config" {
  description = "Ready-to-use wg0.conf content local side of the tunnel. Sensitive since it embeds the private key. PostUp/PostDown disable IPv6 system-wide while the tunnel is up (fail-closed kill switch) since AllowedIPs = 0.0.0.0/0 only covers IPv4 - without this, any AAAA-resolving target would leak local's real IPv6 address around the tunnel entirely."
  sensitive   = true
  value       = <<-EOT
    [Interface]
    Address = ${var.wg_client_tunnel_ip}
    PrivateKey = ${trimspace(data.local_file.client_private_key.content)}
    PostUp = sysctl -w net.ipv6.conf.all.disable_ipv6=1 net.ipv6.conf.default.disable_ipv6=1
    PostDown = sysctl -w net.ipv6.conf.all.disable_ipv6=0 net.ipv6.conf.default.disable_ipv6=0

    [Peer]
    PublicKey = ${trimspace(data.local_file.server_public_key.content)}
    Endpoint = ${aws_eip.proxy.public_ip}:${var.wg_port}
    AllowedIPs = 0.0.0.0/0
    PersistentKeepalive = 25
  EOT
}
