ARG BUILD_ARCH

##
## Stage unico – Debian sia per build che per runtime
## Necessario perché la libreria provision di Dadoum usa simboli glibc
## (backtrace, __res_init) non disponibili su Alpine/musl
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
## Runtime – Debian slim, senza strumenti di build
##
FROM debian:stable-slim

RUN apt-get update && apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        libplist-dev \
        libplist-2.0-4 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/build/anisette-v3-server /opt/anisette-v3-server
RUN chmod +x /opt/anisette-v3-server

RUN mkdir -p /share/anisette-v3/lib

COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 6969
CMD ["/run.sh"]
