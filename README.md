# docker-minecraft-bedrock

The latest official Minecraft Bedrock Edition server (alpha) running on a lightweight, multi-stage Ubuntu 24.04 Docker image.

## Features

* **Optimized Size:** Multi-stage build (~120MB content size).
* **Non-Root Execution:** Server runs under a dedicated `minecraft` user for better security.
* **Dynamic Configuration:** Manage `server.properties` via environment variables.
* **Role-Based Access:** Simplified permissions management using grouped roles.

## Build

```bash
# Fetch latest version and SHA from Mojang, then build
./scripts/build-latest.sh

```

## Run

```bash
docker run -d \
    --name minecraft-bedrock \
    -it \
    -p 19132:19132/udp \
    -v minecraft-bedrock-data:/data \
    --restart unless-stopped \
    --env-file server.properties.env \
    --env-file allowlist.env \
    --env-file permissions.env \
    minecraft-bedrock-server

```

### Console Access

To run commands (e.g., `op <player>`, `stop`, `list`):

```bash
docker attach minecraft-bedrock
# Detach with: Ctrl+P, Ctrl+Q

```

## Configuration

### server.properties

Properties are configured via environment variables with the `bedrock_` prefix using [remco](https://github.com/HeavyHorst/remco).

* **Example:** To change `server-name`, set `bedrock_server_name=MyServer`.
* **Generate template:**

  ```bash
  docker run --rm minecraft-bedrock-server cat /minecraft/example-server.properties.env > server.properties.env
  ```

### Permissions

The entrypoint generates `permissions.json` from role-based environment variables. Each role accepts a comma-separated list of XUIDs.

**Supported roles:** `operators`, `members`, `visitors`

```bash
# Extract the example env file
docker run --rm minecraft-bedrock-server cat /minecraft/example-permissions.env > permissions.env

# Or set directly
docker run -d ... \
    -e operators=1234567890123456,2234567890123457 \
    -e members=3234567890123458 \
    minecraft-bedrock-server
```

### Allowlist

The entrypoint generates `allowlist.json` from environment variables with the format `allowlist_<name>=<xuid>[,ignoresPlayerLimit]`.

```bash
# Extract the example env file
docker run --rm minecraft-bedrock-server cat /minecraft/example-allowlist.env > allowlist.env

# Or set directly
docker run -d ... \
    -e allowlist_SomePlayer=1234567890123456,true \
    -e allowlist_AnotherPlayer=2234567890123457 \
    minecraft-bedrock-server
```

## Technical Details

### Image Architecture

The image uses a multi-stage build to separate build-time dependencies from the runtime environment.

* **Stage 1 (Builder):** Uses `buildpack-deps:noble-curl` to download, verify (SHA256), and extract the server files. It generates the `remco` templates and strips `~100MB` of debug symbols.
* **Stage 2 (Runtime):** Uses `ubuntu:noble`. It contains only the extracted server, `remco`, and essential libraries (`libcurl4`).

### Data Persistence

The `/data` volume stores your world, logs, and generated JSON files. At startup, the container symlinks engine-critical folders (like `definitions` and `resource_packs`) from the read-only `/minecraft` directory into `/data` to ensure the server has everything it needs while keeping your volume clean.

### Looking up XUIDs

You can translate an Xbox Live gamertag to an XUID using the [PlayerDB](https://playerdb.co/) API:

```bash
curl -s "https://playerdb.co/api/player/xbox/<gamertag>" | jq '.data.player.id'

```
