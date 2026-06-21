##
## Stage 1 – Estrai il binario già compilato dall'immagine ufficiale di Dadoum.
##
## Docker BuildKit tira solo i layer necessari dell'immagine sorgente,
## non la esegue. Il risultato è cachato: rebuild future sono istantanee
## finché il digest di dadoum/anisette-v3-server:latest non cambia.
##
## Nota arch: l'immagine Dadoum su Docker Hub è quasi certamente solo amd64.
## Su aarch64 il Supervisor HA fa la build con QEMU (lento solo la prima
## volta; poi il layer è in cache). Se in futuro Dadoum pubblica un
## manifest multi-arch, questo Dockerfile beneficia automaticamente.
##
FROM dadoum/anisette-v3-server:latest AS upstream

##
## Stage 2 – Runtime sulla base ufficiale Home Assistant.
##
## BUILD_FROM viene iniettato dal Supervisor HA in base all'arch:
##   aarch64 → ghcr.io/home-assistant/aarch64-base:3.24
##   amd64   → ghcr.io/home-assistant/amd64-base:3.24
##
ARG BUILD_FROM
FROM ${BUILD_FROM}

# Copia il binario statico dallo stage upstream.
# È compilato con -c "static" quindi non ha dipendenze dinamiche pesanti;
# serve solo libplist a runtime per le routine di provisioning.
COPY --from=upstream /opt/anisette-v3-server /opt/anisette-v3-server

# libplist: richiesta a runtime dalla libreria di provisioning di Dadoum.
# ca-certificates e curl servono all'auto-provisioning (download Apple libs).
RUN apk add --no-cache \
        ca-certificates \
        curl \
        libplist \
    && chmod +x /opt/anisette-v3-server

# /share/anisette-v3/lib è la directory persistente mappata nel volume HA.
# Creata qui per sicurezza; viene popolata al primo avvio tramite run.sh.
RUN mkdir -p /share/anisette-v3/lib

COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 6969
CMD ["/run.sh"]
