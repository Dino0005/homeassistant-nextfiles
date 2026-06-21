ARG BUILD_ARCH

##
## Stage 1 – Compila sulla stessa base HA (Alpine/musl)
## così il binario è garantito compatibile con lo stage runtime
##
FROM ghcr.io/home-assistant/${BUILD_ARCH}-base:3.24 AS builder

RUN apk add --no-cache \
        git \
        curl \
        bash \
        build-base \
        openssl-dev \
        openssl-libs-static \
        zlib-dev \
        zlib-static \
        libplist-dev \
        ldc \
        dub

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
