FROM buildpack-deps:focal-curl

ARG BEDROCK_SERVER_VERSION=1.19.62.01
ARG BEDROCK_SERVER_ZIP=bedrock-server-${BEDROCK_SERVER_VERSION}.zip
ARG BEDROCK_SERVER_ZIP_URL=https://minecraft.azureedge.net/bin-linux/${BEDROCK_SERVER_ZIP}

ARG BEDROCK_SERVER_ZIP_SHA256=aa18f1a49330c67f5dbadfd4d850d607280d03a2420e9b2f0bc267e61bc82691
ARG BEDROCK_SERVER_ZIP_SHA256_FILE=${BEDROCK_SERVER_ZIP}.sha256

ARG REMCO_VER=0.12.3
ARG REMCO_ZIP=remco_${REMCO_VER}_linux_amd64.zip
ARG REMCO_ZIP_URL=https://github.com/HeavyHorst/remco/releases/download/v${REMCO_VER}/${REMCO_ZIP}


RUN groupadd -r -g 999 minecraft
RUN useradd --no-log-init -r -u 999 -g minecraft -d /data minecraft

RUN set -eu && \
    apt update && apt -y install unzip && \
    curl -L "$BEDROCK_SERVER_ZIP_URL" -o "$BEDROCK_SERVER_ZIP" && \
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
    sed -r -e '/^#/! s|^(.+)=(.*)|\1={{ getv("/\1", "\2") }}|g' /minecraft/server.properties -e ':a' -e '/^#/! s|(^.+=)([^,]*)-|\1\2/|;t a' > /etc/remco/templates/server.properties.tmpl && \
    chown -R minecraft:minecraft /data && \
    chmod +x /docker-entrypoint.sh

COPY remco/config /etc/remco/config

EXPOSE 19132/udp

USER minecraft

ENV LD_LIBRARY_PATH=/minecraft

VOLUME ["/data"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/minecraft/bedrock_server"]
