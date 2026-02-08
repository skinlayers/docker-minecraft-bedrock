#!/bin/bash


CURL_USER_AGENT='User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; BEDROCK-UPDATER)'

SERVICE_URL=$(curl -s -A "$CURL_USER_AGENT" \
  "https://www.minecraft.net/webui/config.js" | \
  sed -n '/prod:/,/serviceUrl/{ /serviceUrl/{ s/.*serviceUrl: .//; s/..$//; p; q; }}')

BEDROCK_SERVER_CURRENT_VERSION=$(curl -s \
  "${SERVICE_URL}api/v1.0/download/links" | \
  grep -o 'https[^"]*bin-linux/[^"]*' | \
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

BEDROCK_SERVER_ZIP="bedrock-server-${BEDROCK_SERVER_CURRENT_VERSION}.zip"
BEDROCK_SERVER_ZIP_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/${BEDROCK_SERVER_ZIP}"
BEDROCK_SERVER_ZIP_SHA256=$(curl -s -H "$CURL_USER_AGENT" -L "$BEDROCK_SERVER_ZIP_URL" | shasum -a 256 - | grep -oe "[0-9a-f]\{64\}")


docker pull buildpack-deps:noble-curl
docker build \
  --build-arg BEDROCK_SERVER_VERSION="${BEDROCK_SERVER_CURRENT_VERSION}" \
  --build-arg BEDROCK_SERVER_ZIP_SHA256="${BEDROCK_SERVER_ZIP_SHA256}" \
  -t "minecraft-bedrock-server:${BEDROCK_SERVER_CURRENT_VERSION}" .

exit 0
