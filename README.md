# pi-compose

Everything that runs on the Raspberry Pi, managed with GitOps: **this repo is the source of truth**. The Pi polls `main` every minute and applies it with `docker compose up -d`.

## How a change reaches the Pi

```
PR on an app repo ──► CI builds the image (check only)
        │ merge
        ▼
main of app repo ──► CI pushes ghcr.io/japabu/<app>:sha-<commit>
                     and commits the new tag to compose.yaml here
                                      │
                                      ▼
Pi (pi-compose-deploy.timer, every 1 min) ──► git reset to origin/main
                                              docker compose up -d --remove-orphans
```

- **Roll back:** revert the bump commit here (or set the tag by hand). The Pi applies it within a minute.
- **Change config** (domains, env, a new service): edit `compose.yaml` via PR here.
- **Do not edit files on the Pi.** Local changes are overwritten on the next deploy. `.env` and `letsencrypt/` are git-ignored and kept.

## Apps

| Service | Repo | URL |
|---|---|---|
| paddibot | [Japabu/paddibot](https://github.com/Japabu/paddibot) | Discord bot |

Currently disabled to keep the Pi 3 light (their repos still build images; restore by reverting the removal commit here):
blunderbot + stockfish-server, and the web apps henk, memescraper, flappy behind traefik (`*.pi.japabu.zapto.org`).

## Adding a new app

1. In the app repo, add a `Dockerfile` and copy `.github/workflows/ci.yml` from any app repo above.
2. Add the `PI_COMPOSE_DEPLOY_KEY` secret to the app repo (the private half of the write deploy key on this repo).
3. Add a service to `compose.yaml` here (web apps also need traefik back, see git history) with `image: ghcr.io/japabu/<repo>:latest`. The first CI run on main pins it to a commit tag.
4. Make the ghcr package public (Package settings → visibility) so the Pi can pull it.

## Secrets

Secrets are kept in `~/pi-compose/.env` on the Pi (see `.env.example`). Only reference them from `compose.yaml` as `${NAME}`. After changing `.env`, run `./deploy.sh --force` on the Pi.

## Access & operations

- SSH: `ssh pi@pi` over Tailscale (Tailscale SSH), or `pi@192.168.178.34` over the home WireGuard.
- Deploy logs: `journalctl -u pi-compose-deploy -f`
- Force a deploy now: `~/pi-compose/deploy.sh --force`
- App logs: `docker logs -f <service>`
- Reinstall the timer after editing `systemd/`: `sudo ./systemd/install.sh`
