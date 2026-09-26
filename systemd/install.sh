#!/usr/bin/env bash
# One-time setup (re-run after changing the unit files): sudo ./systemd/install.sh
set -euo pipefail
install -m 644 "$(dirname "$0")"/pi-compose-deploy.{service,timer} /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now pi-compose-deploy.timer
