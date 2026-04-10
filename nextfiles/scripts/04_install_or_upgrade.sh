#!/bin/bash
# =============================================================================
# 04_install_or_upgrade.sh — Prima installazione oppure upgrade con
#                             collegamento config esistente
# =============================================================================
set -e
source /usr/lib/bashio/bashio.sh
source /scripts/env.sh

# ---------------------------------------------------------------------------
# Prima installazione
# ---------------------------------------------------------------------------
if [ ! -f "${DATA_DIR}/config/config.php" ]; then
    bashio::log.info "First run detected. Installing Nextcloud with MariaDB..."

    if [ -z "${ADMIN_PASSWORD}" ]; then
        bashio::log.fatal "Admin password is not set! Please configure it in the add-on options."
        exit 1
    fi

    cd "${NEXTCLOUD_DIR}"

    bashio::log.info "Running occ maintenance:install..."
    su -s /bin/bash apache -c \
        "${PHP_BIN} occ maintenance:install \
        --database='mysql' \
        --database-name='${MARIADB_DATABASE}' \
        --database-host='${MARIADB_HOST}' \
        --database-user='${MARIADB_USERNAME}' \
        --database-pass='${MARIADB_PASSWORD}' \
        --data-dir='${DATA_DIR}/data' \
        --admin-user='${ADMIN_USER}' \
        --admin-pass='${ADMIN_PASSWORD}'" \
        || { bashio::log.fatal 'Error during Nextcloud installation with MariaDB'; exit 1; }

    bashio::log.info "Nextcloud installed successfully with MariaDB!"

    # Sposta config in storage persistente e crea symlink
    cp "${NEXTCLOUD_DIR}/config/config.php" "${DATA_DIR}/config/config.php"
    rm -f "${NEXTCLOUD_DIR}/config/config.php"
    ln -sf "${DATA_DIR}/config/config.php" "${NEXTCLOUD_DIR}/config/config.php"

# ---------------------------------------------------------------------------
# Installazione esistente: collega config e attiva maintenance mode
# ---------------------------------------------------------------------------
else
    bashio::log.info "Existing installation detected. Linking config..."
    rm -f "${NEXTCLOUD_DIR}/config/config.php"
    ln -sf "${DATA_DIR}/config/config.php" "${NEXTCLOUD_DIR}/config/config.php"

    bashio::log.info "Enabling maintenance mode for safe upgrade..."
    su -s /bin/bash apache -c \
        "${PHP_BIN} ${NEXTCLOUD_DIR}/occ maintenance:mode --on" \
        2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Permessi sulle directory di configurazione
# ---------------------------------------------------------------------------
bashio::log.info "Fixing permissions for Nextcloud config directory..."
chown -R apache:apache "${DATA_DIR}/config"
chmod -R 755 "${DATA_DIR}/config"
chown apache:apache "${NEXTCLOUD_DIR}/config"
chmod 755 "${NEXTCLOUD_DIR}/config"
