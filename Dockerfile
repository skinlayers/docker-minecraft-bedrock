FROM buildpack-deps:bionic-curl

ARG BEDROCK_SERVER_VERSION=1.8.0.24
ARG BEDROCK_SERVER_ZIP=bedrock-server-${BEDROCK_SERVER_VERSION}.zip
ARG BEDROCK_SERVER_ZIP_URL=https://minecraft.azureedge.net/bin-linux/${BEDROCK_SERVER_ZIP}

ARG BEDROCK_SERVER_ZIP_SHA256=1b28de35f35e3024bab93547ccfcc6723b62ff930d0f0cc1b7a7c369e8251a1e
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

WORKDIR /data

RUN cp -r /minecraft/behavior_packs /data && \
    cp -r /minecraft/definitions /data && \
    cp -r /minecraft/resource_packs /data && \
    cp -r /minecraft/structures /data && \
    cp /minecraft/server.properties /data && \
    touch /data/ops.json && \
    chown -R minecraft:minecraft /data

EXPOSE 19132/udp \
       19132

USER minecraft

ENV LD_LIBRARY_PATH=/minecraft

VOLUME ["/data"]

CMD ["/minecraft/bedrock_server"]
