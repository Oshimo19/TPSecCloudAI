#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

make pubkey
make init
make fmt
make validate
make plan
# make apply
# make inventory
# make ping
# make ansible
# make test-alert
# make alerts
# make destroy
