FROM buildpack-deps:focal-curl

ARG BEDROCK_SERVER_VERSION=1.16.221.01
ARG BEDROCK_SERVER_ZIP=bedrock-server-${BEDROCK_SERVER_VERSION}.zip
ARG BEDROCK_SERVER_ZIP_URL=https://minecraft.azureedge.net/bin-linux/${BEDROCK_SERVER_ZIP}

ARG BEDROCK_SERVER_ZIP_SHA256=90c86346088c2ccf550f2a98910f37c271422bbad69bf4215f2342c17d76f2eb
ARG BEDROCK_SERVER_ZIP_SHA256_FILE=${BEDROCK_SERVER_ZIP}.sha256

RUN set -eu && \
    groupadd -r -g 999 minecraft && \
    useradd --no-log-init -r -u 999 -g minecraft -d /data minecraft && \
    apt update && apt -y install unzip && \
    curl -L "$BEDROCK_SERVER_ZIP_URL" -o "$BEDROCK_SERVER_ZIP" && \
    echo "$BEDROCK_SERVER_ZIP_SHA256  $BEDROCK_SERVER_ZIP" > "$BEDROCK_SERVER_ZIP_SHA256_FILE" && \
    sha256sum -c "$BEDROCK_SERVER_ZIP_SHA256_FILE" && \
    unzip -q "$BEDROCK_SERVER_ZIP" -d minecraft && \
    chmod +x /minecraft/bedrock_server && \
    rm "$BEDROCK_SERVER_ZIP" "$BEDROCK_SERVER_ZIP_SHA256_FILE" && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./docker-entrypoint.sh /

WORKDIR /data

RUN cp /minecraft/server.properties . && \
    cp /minecraft/whitelist.json . && \
    echo '[]' > permissions.json && \
    chown -R minecraft:minecraft /data && \
    chmod +x /docker-entrypoint.sh

EXPOSE 19132/udp

USER minecraft

ENV LD_LIBRARY_PATH=/minecraft

VOLUME ["/data"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/minecraft/bedrock_server"]
