FROM buildpack-deps:noble-curl

ARG BEDROCK_SERVER_VERSION=1.21.132.3
ARG BEDROCK_SERVER_ZIP=bedrock-server-${BEDROCK_SERVER_VERSION}.zip
ARG BEDROCK_SERVER_ZIP_URL=https://www.minecraft.net/bedrockdedicatedserver/bin-linux/${BEDROCK_SERVER_ZIP}
ARG CURL_USER_AGENT='User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; BEDROCK-UPDATER)'

ARG BEDROCK_SERVER_ZIP_SHA256=07ca4ccf404dfdda02870d47b4a60301a298298018a031989a8c7ef8482d958d
ARG BEDROCK_SERVER_ZIP_SHA256_FILE=${BEDROCK_SERVER_ZIP}.sha256

ARG REMCO_VER=0.12.5
ARG REMCO_ZIP=remco_${REMCO_VER}_linux_amd64.zip
ARG REMCO_ZIP_URL=https://github.com/HeavyHorst/remco/releases/download/v${REMCO_VER}/${REMCO_ZIP}


RUN groupadd -r -g 999 minecraft
RUN useradd --no-log-init -r -u 999 -g minecraft -d /data minecraft

RUN set -eu && \
    apt update && apt -y install unzip && \
    curl -H "$CURL_USER_AGENT" -L "$BEDROCK_SERVER_ZIP_URL" -o "$BEDROCK_SERVER_ZIP" && \
    echo "$BEDROCK_SERVER_ZIP_SHA256  $BEDROCK_SERVER_ZIP" > "$BEDROCK_SERVER_ZIP_SHA256_FILE" && \
    sha256sum -c "$BEDROCK_SERVER_ZIP_SHA256_FILE" && \
    unzip -q "$BEDROCK_SERVER_ZIP" -d minecraft && \
    chmod +x /minecraft/bedrock_server && \
    rm "$BEDROCK_SERVER_ZIP" "$BEDROCK_SERVER_ZIP_SHA256_FILE" && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -L "$REMCO_ZIP_URL" -o "$REMCO_ZIP" && \
    unzip "$REMCO_ZIP" && \
    mv remco_linux /bin/remco && \
    rm "$REMCO_ZIP"

COPY docker-entrypoint.sh /

WORKDIR /data

RUN cp /minecraft/allowlist.json . && \
    cp /minecraft/permissions.json . && \
    cp /minecraft/server.properties . && \
    mkdir -p /etc/remco/templates && \
    # Generate server.properties.tmpl that can be templated at runtime by remco with environment variable values.
    # First expression uncomments commented-out properties so they can also be configured via env vars.
    # Only matches if the value has no spaces (to exclude descriptive comment lines).
    sed -r \
        -e 's/^# ?([a-z][-a-z0-9]*=\S*$)/\1/' \
        -e '/^#/! s|^(.+)=(.*)|\1={{ getv("/\1", "\2") }}|g' \
        -e ':a' -e '/^#/! s|(^.+=)([^,]*)-|\1\2/|;t a' \
        /minecraft/server.properties > /etc/remco/templates/server.properties.tmpl && \
    # Generate example.env with all supported environment variables and their default values.
    sed -n -r \
        -e 's/^([a-z][-a-z0-9]*)=(.*)/BEDROCK_\U\1\E=\2/p; t' \
        -e 's/^# ?([a-z][-a-z0-9]*)=(\S*)$/BEDROCK_\U\1\E=\2/p' \
        /minecraft/server.properties | \
    sed -r ':a; s/^(BEDROCK_[^=]*)-/\1_/; ta' | \
    sed 's/^/#/' > /minecraft/example.env && \
    chown -R minecraft:minecraft /data && \
    chmod +x /docker-entrypoint.sh

COPY remco/config /etc/remco/config

EXPOSE 19132/udp

USER minecraft

ENV LD_LIBRARY_PATH=/minecraft

VOLUME ["/data"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/minecraft/bedrock_server"]
