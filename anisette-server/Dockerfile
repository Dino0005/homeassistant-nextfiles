##
## ARG globale: deve stare PRIMA di qualsiasi FROM per essere visibile
## in tutti gli stage. Il Supervisor HA lo inietta via --build-arg.
##
ARG BUILD_FROM

##
## Stage 1 – Estrai il binario già compilato dall'immagine ufficiale di Dadoum.
##
FROM dadoum/anisette-v3-server:latest AS upstream

##
## Stage 2 – Runtime sulla base ufficiale Home Assistant.
##
FROM ${BUILD_FROM}

# Copia il binario statico dallo stage upstream.
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
