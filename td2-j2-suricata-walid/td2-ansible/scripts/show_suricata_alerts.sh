#!/usr/bin/env bash
set -euo pipefail
sudo tail -n 50 /var/log/suricata/fast.log || true
