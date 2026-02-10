#!/bin/bash
set -euo pipefail

CURL_USER_AGENT='User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; BEDROCK-UPDATER)'

SERVICE_URL=$(curl -s -A "$CURL_USER_AGENT" \
  "https://www.minecraft.net/webui/config.js" | \
  sed -n '/prod:/,/serviceUrl/{ /serviceUrl/{ s/.*serviceUrl: .//; s/..$//; p; q; }}')
[ -n "$SERVICE_URL" ] || { echo "Failed to get service URL from config.js" >&2; exit 1; }

BEDROCK_SERVER_CURRENT_VERSION=$(curl -s \
  "${SERVICE_URL}api/v1.0/download/links" | \
  grep -o 'https[^"]*bin-linux/[^"]*' | \
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
[ -n "$BEDROCK_SERVER_CURRENT_VERSION" ] || { echo "Failed to get bedrock server version" >&2; exit 1; }

echo "Building bedrock server version: ${BEDROCK_SERVER_CURRENT_VERSION}"

BEDROCK_SERVER_ZIP="bedrock-server-${BEDROCK_SERVER_CURRENT_VERSION}.zip"
BEDROCK_SERVER_ZIP_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/${BEDROCK_SERVER_ZIP}"

sha256cmd() { sha256sum "$@" 2>/dev/null || shasum -a 256 "$@"; }
BEDROCK_SERVER_ZIP_SHA256=$(curl -s -H "$CURL_USER_AGENT" -L "$BEDROCK_SERVER_ZIP_URL" | sha256cmd - | grep -oe "[0-9a-f]\{64\}")
[ -n "$BEDROCK_SERVER_ZIP_SHA256" ] || { echo "Failed to compute SHA256 for ${BEDROCK_SERVER_ZIP}" >&2; exit 1; }

docker pull buildpack-deps:noble-curl
docker build \
  --build-arg BEDROCK_SERVER_VERSION="${BEDROCK_SERVER_CURRENT_VERSION}" \
  --build-arg BEDROCK_SERVER_ZIP_SHA256="${BEDROCK_SERVER_ZIP_SHA256}" \
  -t "minecraft-bedrock-server:${BEDROCK_SERVER_CURRENT_VERSION}" .
