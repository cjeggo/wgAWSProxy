#cloud-config
package_update: true

packages:
  - wireguard

write_files:
  - path: /etc/wireguard/wg0.conf
    permissions: '0600'
    content: |
      [Interface]
      Address = ${wg_server_tunnel_ip}
      ListenPort = ${wg_port}
      PrivateKey = ${server_private_key}
      PostUp = iptables -t nat -A POSTROUTING -s ${wg_client_tunnel_ip} -o $(ip -4 route show default | awk '{print $5; exit}') -j MASQUERADE
      PostDown = iptables -t nat -D POSTROUTING -s ${wg_client_tunnel_ip} -o $(ip -4 route show default | awk '{print $5; exit}') -j MASQUERADE

      [Peer]
      PublicKey = ${client_public_key}
      AllowedIPs = ${wg_client_tunnel_ip}

  - path: /etc/sysctl.d/99-wg-forward.conf
    permissions: '0644'
    content: |
      net.ipv4.ip_forward = 1

runcmd:
  - sysctl --system
  - systemctl enable --now wg-quick@wg0
