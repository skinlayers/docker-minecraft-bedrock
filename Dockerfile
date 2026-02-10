# --- Stage 1: Builder ---
FROM buildpack-deps:noble-curl AS builder

ARG BEDROCK_SERVER_VERSION=1.21.132.3
ARG BEDROCK_SERVER_ZIP=bedrock-server-${BEDROCK_SERVER_VERSION}.zip
ARG BEDROCK_SERVER_ZIP_URL=https://www.minecraft.net/bedrockdedicatedserver/bin-linux/${BEDROCK_SERVER_ZIP}
ARG BEDROCK_SERVER_ZIP_SHA256=07ca4ccf404dfdda02870d47b4a60301a298298018a031989a8c7ef8482d958d
ARG CURL_USER_AGENT='User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; BEDROCK-UPDATER)'

ARG REMCO_VER=0.12.5
ARG REMCO_ZIP=remco_${REMCO_VER}_linux_amd64.zip
ARG REMCO_ZIP_URL=https://github.com/HeavyHorst/remco/releases/download/v${REMCO_VER}/${REMCO_ZIP}

WORKDIR /tmp

RUN apt-get update && apt-get install -y unzip && \
    curl -L "$REMCO_ZIP_URL" -o "$REMCO_ZIP" && \
    unzip "$REMCO_ZIP" && \
    mv remco_linux /tmp/remco && \
    curl -H "$CURL_USER_AGENT" -L "$BEDROCK_SERVER_ZIP_URL" -o "$BEDROCK_SERVER_ZIP" && \
    echo "$BEDROCK_SERVER_ZIP_SHA256  $BEDROCK_SERVER_ZIP" > server.sha256 && \
    sha256sum -c server.sha256 && \
    # Unzip to a clean folder and REMOVE the zip immediately
    mkdir /minecraft_files && \
    unzip -q "$BEDROCK_SERVER_ZIP" -d /minecraft_files && \
    rm "$BEDROCK_SERVER_ZIP"

RUN mkdir -p /etc/remco/templates && \
    sed -r \
        -e 's/^# ?([a-z][-a-z0-9]*=\S*$)/\1/' \
        -e '/^#/! s|^(.+)=(.*)|\1={{ getv("/\1", "\2") }}|g' \
        /minecraft_files/server.properties | \
    sed -r ':l; s|(getv\("/[^"]*)-|\1/|; t l' \
        > /etc/remco/templates/server.properties.tmpl && \
    # Generate example-server.properties.env from server.properties
    sed -n -r \
        -e 's/^([a-z][-a-z0-9]*)=(.*)/bedrock_\1=\2/p; t' \
        -e 's/^# ?([a-z][-a-z0-9]*)=(\S*)$/bedrock_\1=\2/p' \
        /minecraft_files/server.properties | \
    sed -r -e ':l; s/^(bedrock_[a-z0-9_]*)-/\1_/; t l' -e 's/^/#/' \
        > /minecraft_files/example-server.properties.env

# --- Stage 2: Runtime ---
FROM ubuntu:noble

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r -g 999 minecraft && \
    useradd --no-log-init -r -u 999 -g minecraft -d /data minecraft

# USE --chown to set permissions during the copy (Prevents layer bloat)
COPY --from=builder --chown=minecraft:minecraft /tmp/remco /bin/remco
COPY --from=builder --chown=minecraft:minecraft /minecraft_files /minecraft
COPY --from=builder /etc/remco/templates /etc/remco/templates
COPY --chown=minecraft:minecraft remco/config /etc/remco/config
COPY --chown=minecraft:minecraft examples/example-permissions.env examples/example-allowlist.env /minecraft/
COPY --chown=minecraft:minecraft docker-entrypoint.sh /

WORKDIR /data
# Only chown the /data volume directory, not the /minecraft engine files
RUN chown minecraft:minecraft /data && chmod +x /docker-entrypoint.sh

USER minecraft
ENV LD_LIBRARY_PATH=/minecraft
EXPOSE 19132/udp
VOLUME ["/data"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/minecraft/bedrock_server"]
