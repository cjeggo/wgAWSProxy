#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

case "${1:-}" in
  up)
    terraform output -raw wg_config | sudo tee /etc/wireguard/wg0.conf > /dev/null
    sudo chmod 600 /etc/wireguard/wg0.conf
    sudo wg-quick up wg0
    sudo wg show wg0
    ;;
  down)
    if sudo ip link show wg0 &>/dev/null; then
      sudo wg-quick down wg0
    else
      echo "wg0 not up, nothing to tear down"
    fi
    ;;
  status)
    sudo wg show wg0
    ;;
  *)
    echo "usage: $0 {up|down|status}" >&2
    exit 1
    ;;
esac
