#!/usr/bin/env bash
# Reconciles the Pi with origin/main of this repo. Runs every minute via systemd (pi-compose-deploy.timer).
# Usage: ./deploy.sh [--force]    (--force redeploys even if origin/main was already applied)
set -euo pipefail
cd "$(dirname "$0")"

export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/pi_compose_deploy -o IdentitiesOnly=yes -o BatchMode=yes"
git fetch --quiet origin main
target=$(git rev-parse origin/main)

if [[ "${1:-}" != "--force" && -f .deployed && "$(cat .deployed)" == "$target" ]]; then
  exit 0
fi

echo "Deploying ${target:0:7}: $(git log -1 --format=%s "$target")"
git reset --hard --quiet "$target"
docker compose up -d --remove-orphans
echo "$target" > .deployed
docker image prune -af >/dev/null
echo "Deployed ${target:0:7}"
