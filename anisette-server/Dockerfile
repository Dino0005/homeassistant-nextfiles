ARG BUILD_ARCH

##
## Stage 1 – Compila su Debian (glibc), unico ambiente compatibile
## con la libreria provision di Dadoum che usa backtrace() di glibc
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
## Stage 2 – Runtime sulla base Home Assistant (Alpine/musl)
## gcompat fornisce la shim glibc su musl, necessaria per il binario
## compilato su Debian. libc6-compat aggiunge ld-linux loader.
##
FROM ghcr.io/home-assistant/${BUILD_ARCH}-base:3.24

RUN apk add --no-cache \
        ca-certificates \
        curl \
        libplist \
        gcompat \
        libc6-compat

COPY --from=builder /opt/build/anisette-v3-server /opt/anisette-v3-server
RUN chmod +x /opt/anisette-v3-server

RUN mkdir -p /share/anisette-v3/lib

COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 6969
CMD ["/run.sh"]
