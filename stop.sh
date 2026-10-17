#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

./wg.sh down || echo "wg down step failed or was a no-op, continuing to destroy regardless"
terraform destroy -auto-approve
