#!/bin/bash
# =============================================================================
# 05_configure_nextcloud.sh — Configurazione sistema Nextcloud via occ
#   - APCu / Redis cache
#   - Preview providers
#   - Session lifetime
#   - Snowflake ID
#   - Trusted domains & proxies
#   - Overwrite settings (reverse proxy)
# =============================================================================
set -e
source /usr/lib/bashio/bashio.sh
source /scripts/env.sh

# Shorthand per eseguire occ come utente apache (errori non fatali)
occ() {
    su -s /bin/bash apache -c "${PHP_BIN} ${NEXTCLOUD_DIR}/occ $*" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# APCu — cache locale
# ---------------------------------------------------------------------------
bashio::log.info "Configuring APCu as local memory cache..."
occ "config:system:set memcache.local --type=string --value='\\OC\\Memcache\\APCu'"

# ---------------------------------------------------------------------------
# Preview providers (ImageMagick + FFmpeg)
# ---------------------------------------------------------------------------
bashio::log.info "Configuring preview providers (ImageMagick + FFmpeg)..."

PROVIDERS=(
    PNG JPEG GIF BMP XBitmap MP3 TXT MarkDown PDF SVG Font
    HEIC Movie MSOfficeDoc MSOffice2003 MSOffice2007
    OpenDocument Krita Image
)

# Nota: OC\Preview\Imaginary rimosso — richiede server Imaginary esterno
for i in "${!PROVIDERS[@]}"; do
    occ "config:system:set enabledPreviewProviders ${i} --value='OC\\\\Preview\\\\${PROVIDERS[$i]}'"
done

bashio::log.info "✓ Preview providers configured (${#PROVIDERS[@]} providers)"

# Pulizia migration_lock PRIMA della configurazione Redis e del repair
# (previene errori durante maintenance:repair — originale riga 382)
bashio::log.info "Cleaning up Circles migration lock (pre-repair)..."
occ "config:app:delete circles migration_lock"

# ---------------------------------------------------------------------------
# Redis (opzionale)
# ---------------------------------------------------------------------------
if [[ -n "${REDIS_HOST}" ]] && nc -z "${REDIS_HOST}" "${REDIS_PORT}" 2>/dev/null; then
    bashio::log.info "=========================================="
    bashio::log.info "Redis detected at ${REDIS_HOST}:${REDIS_PORT}"
    bashio::log.info "=========================================="

    occ "config:system:set memcache.locking     --type=string --value='\\OC\\Memcache\\Redis'"
    occ "config:system:set memcache.distributed --type=string --value='\\OC\\Memcache\\Redis'"

    # Ricrea la configurazione Redis da zero (evita chiavi orfane)
    occ "config:system:delete redis"
    occ "config:system:set redis --type=array"
    occ "config:system:set redis host     --type=string  --value='${REDIS_HOST}'"
    occ "config:system:set redis port     --type=integer --value='${REDIS_PORT}'"

    if [[ -n "${REDIS_PASSWORD}" ]]; then
        occ "config:system:set redis password --type=string --value='${REDIS_PASSWORD}'"
    fi

    bashio::log.info "✓ Redis integration completed!"

elif [[ -n "${REDIS_HOST}" ]]; then
    bashio::log.warning "Redis configured but not reachable at ${REDIS_HOST}:${REDIS_PORT}"
    bashio::log.warning "Continuing without Redis - only APCu cache will be used"
else
    bashio::log.info "No Redis configured - using only APCu for local cache"
fi

# ---------------------------------------------------------------------------
# Sessioni
# ---------------------------------------------------------------------------
bashio::log.info "Configuring Nextcloud session parameters..."
occ "config:system:set session_lifetime  --value=86400 --type=integer"
occ "config:system:set session_keepalive --value=true  --type=boolean"
bashio::log.info "✓ Session lifetime set to 24 hours"

# ---------------------------------------------------------------------------
# Snowflake ID (NC33+)
# ---------------------------------------------------------------------------
bashio::log.info "Configuring Snowflake ID..."
EXISTING_ID=$(su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:get snowflake.server_id" 2>/dev/null || echo "")

if [ -z "$EXISTING_ID" ]; then
    NEW_SERVER_ID=$(echo "$(hostname)" | cksum | awk '{print $1 % 1024}')
    occ "config:system:set snowflake.server_id --value='${NEW_SERVER_ID}' --type=integer"
    bashio::log.info "✓ New Snowflake ID generated: ${NEW_SERVER_ID}"
else
    bashio::log.info "✓ Snowflake ID already exists: ${EXISTING_ID}"
fi

# ---------------------------------------------------------------------------
# Trusted domains
# ---------------------------------------------------------------------------
bashio::log.info "Configuring trusted domains..."
occ "config:system:delete trusted_domains"

DOMAIN_COUNT=$(jq -r '.trusted_domains | length' ${CONFIG_FILE})
bashio::log.info "Found ${DOMAIN_COUNT} trusted domains in configuration"

for i in $(seq 0 $((DOMAIN_COUNT - 1))); do
    DOMAIN=$(jq -r ".trusted_domains[${i}]" ${CONFIG_FILE})
    if [[ -n "${DOMAIN}" ]]; then
        bashio::log.info "Adding trusted domain [${i}]: ${DOMAIN}"
        occ "config:system:set trusted_domains ${i} --value='${DOMAIN}'"
    fi
done

# ---------------------------------------------------------------------------
# Trusted proxies
# ---------------------------------------------------------------------------
bashio::log.info "Configuring trusted proxies..."
occ "config:system:delete trusted_proxies"

PROXY_COUNT=$(jq -r '.trusted_proxies | length' ${CONFIG_FILE})
bashio::log.info "Found ${PROXY_COUNT} trusted proxies in configuration"

for i in $(seq 0 $((PROXY_COUNT - 1))); do
    PROXY=$(jq -r ".trusted_proxies[${i}]" ${CONFIG_FILE})
    if [[ -n "${PROXY}" ]]; then
        bashio::log.info "Adding trusted proxy [${i}]: ${PROXY}"
        occ "config:system:set trusted_proxies ${i} --value='${PROXY}'"
    fi
done

# ---------------------------------------------------------------------------
# Overwrite settings (reverse proxy)
# ---------------------------------------------------------------------------
FIRST_DOMAIN=$(jq -r '.trusted_domains[0] // "localhost"' ${CONFIG_FILE})
bashio::log.info "Configuring overwrite settings for reverse proxy (domain: ${FIRST_DOMAIN})..."

occ "config:system:set overwritehost     --value='${FIRST_DOMAIN}'"
occ "config:system:set overwriteprotocol --value='https'"
occ "config:system:set overwrite.cli.url --value='https://${FIRST_DOMAIN}'"
occ "config:system:set overwritewebroot  --value='/nextfiles'"

# Temp directory (necessario per upgrade NC33+)
occ "config:system:set tempdirectory --value='${DATA_DIR}/tmp'"

# Server ID
occ "config:system:set serverid --value='1' --type=integer"

# Forwarded headers (sicurezza reverse proxy)
occ "config:system:set forwarded_for_headers 0 --value='HTTP_X_FORWARDED_FOR'"
occ "config:system:set forwarded_for_headers 1 --value='HTTP_X_REAL_IP'"

# Regione telefonica
bashio::log.info "Setting default phone region to: ${DEFAULT_PHONE_REGION}"
occ "config:system:set default_phone_region --value='${DEFAULT_PHONE_REGION}'"

# Finestra di manutenzione (ore 3)
occ "config:system:set maintenance_window_start --value='3' --type=integer"

bashio::log.info "✓ Nextcloud system configuration complete"
