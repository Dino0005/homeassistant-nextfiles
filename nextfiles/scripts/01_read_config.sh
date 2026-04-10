#!/bin/bash
# =============================================================================
# 01_read_config.sh — Lettura configurazione e test connessione MariaDB
# =============================================================================
set -e
source /usr/lib/bashio/bashio.sh
source /scripts/env.sh

bashio::log.info "Reading configuration from ${CONFIG_FILE}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    bashio::log.fatal "Configuration file /data/options.json not found!"
    exit 1
fi

# ---------------------------------------------------------------------------
# Lettura parametri da options.json
# ---------------------------------------------------------------------------
export ADMIN_USER=$(jq -r '.admin_user // "admin"' ${CONFIG_FILE})
export ADMIN_PASSWORD=$(jq -r '.admin_password // ""' ${CONFIG_FILE})
export MAX_UPLOAD=$(jq -r '.max_upload_size // "512M"' ${CONFIG_FILE})
export MEMORY_LIMIT=$(jq -r '.memory_limit // "512M"' ${CONFIG_FILE})
export DEFAULT_PHONE_REGION=$(jq -r '.default_phone_region // "IT"' ${CONFIG_FILE})

export REDIS_HOST=$(jq -r '.redis_host // ""' ${CONFIG_FILE})
export REDIS_PORT=$(jq -r '.redis_port // 6379' ${CONFIG_FILE})
export REDIS_PASSWORD=$(jq -r '.redis_password // ""' ${CONFIG_FILE})

export MARIADB_HOST=$(jq -r '.mariadb_host // "core-mariadb"' ${CONFIG_FILE})
export MARIADB_DATABASE=$(jq -r '.mariadb_database // "nextcloud"' ${CONFIG_FILE})
export MARIADB_USERNAME=$(jq -r '.mariadb_username // "nextcloud"' ${CONFIG_FILE})
export MARIADB_PASSWORD=$(jq -r '.mariadb_password // ""' ${CONFIG_FILE})

# ---------------------------------------------------------------------------
# Validazione
# ---------------------------------------------------------------------------
if [ -z "$MARIADB_HOST" ] || [ -z "$MARIADB_PASSWORD" ]; then
    bashio::log.fatal "MariaDB configuration incomplete! Please set mariadb_host and mariadb_password."
    exit 1
fi

bashio::log.info "Database type: MariaDB"
bashio::log.info "MariaDB host: ${MARIADB_HOST}"
bashio::log.info "MariaDB database: ${MARIADB_DATABASE}"
bashio::log.info "MariaDB username: ${MARIADB_USERNAME}"

# ---------------------------------------------------------------------------
# Rilevamento client MySQL/MariaDB
# ---------------------------------------------------------------------------
export MYSQL_CMD=""
if command -v mariadb &>/dev/null; then
    export MYSQL_CMD="mariadb"
    bashio::log.info "Using MariaDB client: $(which mariadb)"
elif command -v mysql &>/dev/null; then
    export MYSQL_CMD="mysql"
    bashio::log.info "Using MySQL client: $(which mysql)"
else
    bashio::log.fatal "Neither MariaDB nor MySQL client found! This is a container build issue."
    exit 1
fi

# ---------------------------------------------------------------------------
# Creazione file di configurazione temporaneo (password sicura)
# ---------------------------------------------------------------------------
bashio::log.info "Creating temporary MySQL config file..."
cat > "${MYSQL_CONFIG}" << EOF
[client]
host=${MARIADB_HOST}
user=${MARIADB_USERNAME}
password=${MARIADB_PASSWORD}
port=3306
ssl=0
skip-ssl
EOF
chmod 600 "${MYSQL_CONFIG}"

# ---------------------------------------------------------------------------
# Test connessione
# ---------------------------------------------------------------------------
bashio::log.info "Testing MariaDB connection to ${MARIADB_HOST}:3306..."

set +e
CONNECTION_TEST=$(${MYSQL_CMD} --defaults-extra-file="${MYSQL_CONFIG}" -e "SELECT 1 AS test;" 2>&1)
CONNECTION_RESULT=$?
set -e

if [ $CONNECTION_RESULT -ne 0 ]; then
    bashio::log.fatal "=========================================="
    bashio::log.fatal "Cannot connect to MariaDB!"
    bashio::log.fatal "Exit code: ${CONNECTION_RESULT}"
    bashio::log.fatal "=========================================="
    bashio::log.fatal "Error output:"
    bashio::log.fatal "${CONNECTION_TEST}"
    bashio::log.fatal "=========================================="
    bashio::log.fatal ""
    bashio::log.fatal "Troubleshooting checklist:"
    bashio::log.fatal "1. Is MariaDB add-on running? Check in Home Assistant add-ons page"
    bashio::log.fatal "2. MariaDB configuration must have:"
    bashio::log.fatal "   - Database: ${MARIADB_DATABASE}"
    bashio::log.fatal "   - Username: ${MARIADB_USERNAME}"
    bashio::log.fatal "   - Password: (must match exactly)"
    bashio::log.fatal "3. Did you restart MariaDB after configuration changes?"
    bashio::log.fatal "4. Check MariaDB logs for authentication errors"
    bashio::log.fatal ""

    if ping -c 1 -W 2 "${MARIADB_HOST}" &>/dev/null; then
        bashio::log.info "✓ Host ${MARIADB_HOST} is reachable via ping"
    else
        bashio::log.fatal "✗ Host ${MARIADB_HOST} is NOT reachable via ping!"
    fi

    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/${MARIADB_HOST}/3306" 2>/dev/null; then
        bashio::log.info "✓ Port 3306 on ${MARIADB_HOST} is open"
    else
        bashio::log.fatal "✗ Port 3306 on ${MARIADB_HOST} is not accessible!"
    fi

    exit 1
fi

bashio::log.info "=========================================="
bashio::log.info "✓ MariaDB connection successful!"
bashio::log.info "=========================================="
