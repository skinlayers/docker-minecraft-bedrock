FROM buildpack-deps:bionic-curl as builder

ARG BEDROCK_SERVER_VERSION=1.7.0.13
ARG BEDROCK_SERVER_ZIP=bedrock-server-${BEDROCK_SERVER_VERSION}.zip
ARG BEDROCK_SERVER_ZIP_URL=https://minecraft.azureedge.net/bin-linux/${BEDROCK_SERVER_ZIP}

ARG BEDROCK_SERVER_ZIP_SHA256=02b9afcdc55a4c37f8ba6c6a9ae32d45aaebf0da06223f9ab13e00908202135d
ARG BEDROCK_SERVER_ZIP_SHA256_FILE=${BEDROCK_SERVER_ZIP}.sha256

RUN set -eu && \
    apt update && apt -y install curl unzip && \
    curl -L "$BEDROCK_SERVER_ZIP_URL" -o "$BEDROCK_SERVER_ZIP" && \
    echo "$BEDROCK_SERVER_ZIP_SHA256  $BEDROCK_SERVER_ZIP" > "$BEDROCK_SERVER_ZIP_SHA256_FILE" && \
    sha256sum -c "$BEDROCK_SERVER_ZIP_SHA256_FILE" && \
    unzip "$BEDROCK_SERVER_ZIP" -d bedrock && \
    cp bedrock/server.properties "bedrock/server.properties-${BEDROCK_SERVER_VERSION}.unedited" && \
    rm "$BEDROCK_SERVER_ZIP" "$BEDROCK_SERVER_ZIP_SHA256_FILE" && \
    apt clean && \
    rm -r /var/lib/apt/lists/*

FROM ubuntu:bionic

COPY --from=builder /bedrock /

WORKDIR /bedrock

ENV LD_LIBRARY_PATH=/bedrock

EXPOSE 19132/udp \
       19132

VOLUME ["/bedrock"]

CMD ["./bedrock_server"]
