ARG BUILD_ARCH

##
## Stage 1 – Binario da immagine ufficiale Dadoum
##
FROM dadoum/anisette-v3-server:latest AS upstream

##
## Stage 2 – Runtime sulla base ufficiale Home Assistant
##
FROM ghcr.io/home-assistant/${BUILD_ARCH}-base:3.24

COPY --from=upstream /opt/anisette-v3-server /opt/anisette-v3-server

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
