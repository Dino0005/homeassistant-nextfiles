#!/usr/bin/with-contenv /bin/bash
# shellcheck shell=bash
# =============================================================================
# run.sh — Entry point del container
# Carica le variabili condivise, esegue gli script in sequenza,
# poi avvia Apache in foreground.
# =============================================================================
set -e
source /usr/lib/bashio/bashio.sh
source /scripts/env.sh

bashio::log.info "Starting Nextfiles setup..."

SCRIPTS=(
    /scripts/01_read_config.sh
    /scripts/02_setup_folders.sh
    /scripts/03_setup_php.sh
    /scripts/04_install_or_upgrade.sh
    /scripts/05_configure_nextcloud.sh
    /scripts/06_finalize.sh
)

for script in "${SCRIPTS[@]}"; do
    bashio::log.info "=========================================="
    bashio::log.info "▶ $(basename $script)"
    bashio::log.info "=========================================="
    # source invece di bash: preserva le variabili exportate tra gli script
    source "$script" || { bashio::log.fatal "Failed at: $script"; exit 1; }
done

bashio::log.info "=========================================="
bashio::log.info "Nextfiles is ready! Using MariaDB + APCu."
if [[ -n "${REDIS_HOST}" ]] && nc -z "${REDIS_HOST}" "${REDIS_PORT}" 2>/dev/null; then
    bashio::log.info "Redis integration active for file locking and distributed cache."
fi
bashio::log.info "=========================================="

# Aumenta stack size a 64MB per evitare segfault su operazioni ricorsive
# (default Alpine 8MB è insufficiente per Nextcloud)
bashio::log.info "Starting Apache with increased stack size (64MB)..."
exec sh -c 'ulimit -s 65536 && exec httpd -D FOREGROUND'
