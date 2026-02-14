ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Installazione Redis e dipendenze
# --no-cache evita di salvare gli indici apk nell'immagine (riduce dimensioni)
RUN apk add --no-cache \
    redis \
    bash \
    && rm -rf /var/cache/apk/*

# Creazione della directory per il database Redis
# NOTA: /data è un volume montato da Home Assistant a runtime.
# Creiamo la struttura nell'immagine come fallback e per test locali.
# I permessi definitivi vengono impostati in run.sh dopo il mount del volume.
RUN mkdir -p /data/redis && \
    chown -R redis:redis /data/redis && \
    chmod 755 /data/redis

# Verifica che l'utente redis esista (debug)
RUN id redis || echo "WARNING: redis user not found"

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

# Health check - verifica che Redis risponda
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD redis-cli ping || exit 1

# Expose Redis port
EXPOSE 6379

# Avvia Redis tramite run.sh
CMD ["/run.sh"]
