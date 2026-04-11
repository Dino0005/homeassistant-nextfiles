#!/bin/bash
# =============================================================================
# 02_setup_folders.sh — Creazione cartelle, permessi, sessioni, symlink apps2
# =============================================================================
set -e
source /usr/lib/bashio/bashio.sh
source /scripts/env.sh

# ---------------------------------------------------------------------------
# Verifica esistenza utente apache
# ---------------------------------------------------------------------------
if ! id apache &>/dev/null; then
    bashio::log.info "Creating apache user..."
    addgroup -g 48 apache
    adduser -D -u 48 -G apache -s /sbin/nologin apache
fi

# ---------------------------------------------------------------------------
# Creazione struttura cartelle dati
# ---------------------------------------------------------------------------
bashio::log.info "Setting up data directory: ${DATA_DIR}"
mkdir -p "${DATA_DIR}/data"
mkdir -p "${DATA_DIR}/config"
mkdir -p "${DATA_DIR}/apps_custom"
mkdir -p "${DATA_DIR}/tmp"   # Necessario per upgrade a NC33+

# Permessi generali
bashio::log.info "Fixing permissions on ${DATA_DIR}..."
chown -R apache:apache "${DATA_DIR}"
chmod -R 755 "${DATA_DIR}"

# ---------------------------------------------------------------------------
# Directory sessioni persistenti (permessi speciali 1777)
# Deve essere impostata DOPO il chmod -R 755 sopra
# ---------------------------------------------------------------------------
bashio::log.info "Setting up persistent session directory..."
mkdir -p "${DATA_DIR}/sessions"
chown apache:apache "${DATA_DIR}/sessions"
chmod 1777 "${DATA_DIR}/sessions"

PERMS=$(stat -c "%a" "${DATA_DIR}/sessions" 2>/dev/null || echo "0")
if [ "$PERMS" != "1777" ]; then
    bashio::log.warning "Session directory permissions incorrect ($PERMS), fixing..."
    chmod 1777 "${DATA_DIR}/sessions"
fi
bashio::log.info "✓ Session directory configured at ${DATA_DIR}/sessions (perms: 1777)"

# ---------------------------------------------------------------------------
# Symlink apps2 → apps_custom (directory persistente per le app)
# ---------------------------------------------------------------------------
bashio::log.info "Setting up custom apps directory..."
if [ ! -L "${NEXTCLOUD_DIR}/apps2" ]; then
    rm -rf "${NEXTCLOUD_DIR}/apps2"
    ln -sf "${DATA_DIR}/apps_custom" "${NEXTCLOUD_DIR}/apps2"
fi
chown -R apache:apache "${DATA_DIR}/apps_custom"
bashio::log.info "✓ Custom apps directory linked at ${NEXTCLOUD_DIR}/apps2"

# ---------------------------------------------------------------------------
# Cartella backup updater (evita warning NC)
# ---------------------------------------------------------------------------
bashio::log.info "Checking for updater backup folder..."
APPDATA_FOLDER=$(find "${DATA_DIR}/data" -maxdepth 1 -type d -name "appdata_oc*" 2>/dev/null | head -n 1)

if [ -n "$APPDATA_FOLDER" ]; then
    UNIQUE_CODE=$(basename "$APPDATA_FOLDER" | sed 's/appdata_//')
    UPDATER_FOLDER="${DATA_DIR}/data/updater-${UNIQUE_CODE}"
    BACKUPS_FOLDER="${UPDATER_FOLDER}/backups"

    if [ ! -d "$BACKUPS_FOLDER" ]; then
        bashio::log.info "Creating updater backup folder: ${BACKUPS_FOLDER}"
        mkdir -p "$BACKUPS_FOLDER"
        chown -R apache:apache "$UPDATER_FOLDER"
        chmod -R 755 "$UPDATER_FOLDER"
    else
        bashio::log.info "Updater backup folder already exists"
    fi
else
    bashio::log.info "No appdata folder found yet (first install)"
fi
