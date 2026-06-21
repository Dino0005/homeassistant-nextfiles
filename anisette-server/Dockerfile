ARG BUILD_ARCH

##
## Stage 1 – Compila da sorgente su Debian arm64
## (il Supervisor fa girare questo stage nativo su aarch64 grazie a buildx)
##
FROM debian:stable-slim AS builder

RUN apt-get update && apt-get install --no-install-recommends -y \
        ca-certificates \
        ldc \
        git \
        clang \
        dub \
        libz-dev \
        libssl-dev \
        libplist-dev \
        libplist-2.0-4 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/build
RUN git clone --depth 1 https://github.com/Dadoum/anisette-v3-server.git . \
    && DC=ldc2 dub build -c "static" --build-mode allAtOnce -b release --compiler=ldc2

##
## Stage 2 – Runtime sulla base Home Assistant
##
FROM ghcr.io/home-assistant/${BUILD_ARCH}-base:3.24

COPY --from=builder /opt/build/anisette-v3-server /opt/anisette-v3-server

RUN apk add --no-cache \
        ca-certificates \
        curl \
        libplist \
    && chmod +x /opt/anisette-v3-server

RUN mkdir -p /share/anisette-v3/lib

COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 6969
CMD ["/run.sh"]
