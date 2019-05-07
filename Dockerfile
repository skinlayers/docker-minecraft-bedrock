FROM buildpack-deps:bionic-curl

ARG BEDROCK_SERVER_VERSION=1.11.2.1
ARG BEDROCK_SERVER_ZIP=bedrock-server-${BEDROCK_SERVER_VERSION}.zip
ARG BEDROCK_SERVER_ZIP_URL=https://minecraft.azureedge.net/bin-linux/${BEDROCK_SERVER_ZIP}

ARG BEDROCK_SERVER_ZIP_SHA256=ca1bf812f4b288ebf3ea23c0021cc4b4fc068d4a37f52c18feece9ebd5d07f48
ARG BEDROCK_SERVER_ZIP_SHA256_FILE=${BEDROCK_SERVER_ZIP}.sha256

RUN set -eu && \
    groupadd -r -g 999 minecraft && \
    useradd --no-log-init -r -u 999 -g minecraft -d /data minecraft && \
    apt update && apt -y install unzip && \
    curl -L "$BEDROCK_SERVER_ZIP_URL" -o "$BEDROCK_SERVER_ZIP" && \
    echo "$BEDROCK_SERVER_ZIP_SHA256  $BEDROCK_SERVER_ZIP" > "$BEDROCK_SERVER_ZIP_SHA256_FILE" && \
    sha256sum -c "$BEDROCK_SERVER_ZIP_SHA256_FILE" && \
    unzip -q "$BEDROCK_SERVER_ZIP" -d minecraft && \
    rm "$BEDROCK_SERVER_ZIP" "$BEDROCK_SERVER_ZIP_SHA256_FILE" && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./docker-entrypoint.sh /

WORKDIR /data

RUN cp /minecraft/server.properties . && \
    cp /minecraft/whitelist.json . && \
    touch ops.json && \
    chown -R minecraft:minecraft /data && \
    chmod +x /docker-entrypoint.sh

EXPOSE 19132/udp \
       19132

USER minecraft

ENV LD_LIBRARY_PATH=/minecraft

VOLUME ["/data"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/minecraft/bedrock_server"]
