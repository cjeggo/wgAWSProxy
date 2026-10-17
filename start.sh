#!/usr/bin/env bash
# ponytail: apply + bring the tunnel up in one go. Add -var/-var-file passthrough
# only if a real need for per-engagement overrides shows up.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

terraform apply -auto-approve
./wg.sh up
