ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Installazione Redis e Bash (necessario per lo script run.sh)
# Usiamo --no-cache per non appesantire l'immagine con i file degli indici apk
RUN apk add --no-cache \
    redis \
    bash

# Creazione della directory per il database Redis (/data è persistente in HA)
# NOTA: I permessi vengono gestiti in run.sh dopo che il pacchetto redis ha creato l'utente
RUN mkdir -p /data/redis

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

# Expose Redis port
EXPOSE 6379

CMD ["/run.sh"]
