#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Starting Nextfiles setup..."

# Get configuration
ADMIN_USER=$(bashio::config 'admin_user')
ADMIN_PASSWORD=$(bashio::config 'admin_password')
MAX_UPLOAD=$(bashio::config 'max_upload_size')
MEMORY_LIMIT=$(bashio::config 'memory_limit')

# Get Redis configuration (optional)
REDIS_HOST=$(bashio::config 'redis_host')
REDIS_PORT=$(bashio::config 'redis_port')
REDIS_PASSWORD=$(bashio::config 'redis_password')

# Get MariaDB configuration
MARIADB_HOST=$(bashio::config 'mariadb_host')
MARIADB_DATABASE=$(bashio::config 'mariadb_database')
MARIADB_USERNAME=$(bashio::config 'mariadb_username')
MARIADB_PASSWORD=$(bashio::config 'mariadb_password')

# Validate MariaDB configuration
if [ -z "$MARIADB_HOST" ] || [ -z "$MARIADB_PASSWORD" ]; then
    bashio::log.fatal "MariaDB configuration incomplete! Please set mariadb_host and mariadb_password."
    exit 1
fi

bashio::log.info "Database type: MariaDB"
bashio::log.info "MariaDB host: ${MARIADB_HOST}"
bashio::log.info "MariaDB database: ${MARIADB_DATABASE}"
bashio::log.info "MariaDB username: ${MARIADB_USERNAME}"

# Test MariaDB connection
bashio::log.info "Testing MariaDB connection..."
bashio::log.info "Attempting connection to ${MARIADB_HOST}:3306..."
bashio::log.info "Using database: ${MARIADB_DATABASE}, username: ${MARIADB_USERNAME}"

# First check if mariadb or mysql command exists
MYSQL_CMD=""
if command -v mariadb &>/dev/null; then
    MYSQL_CMD="mariadb"
    bashio::log.info "Using MariaDB client: $(which mariadb)"
elif command -v mysql &>/dev/null; then
    MYSQL_CMD="mysql"
    bashio::log.info "Using MySQL client: $(which mysql)"
else
    bashio::log.fatal "Neither MariaDB nor MySQL client found! This is a container build issue."
    exit 1
fi

# Create a temporary MySQL config file for secure password passing
MYSQL_CONFIG="/tmp/mysql_client.cnf"
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

bashio::log.info "Config file created, attempting connection..."

# Try connection with config file (more secure than command line)
set +e  # Don't exit on error, we want to capture it
CONNECTION_TEST=$(${MYSQL_CMD} --defaults-extra-file="${MYSQL_CONFIG}" -e "SELECT 1 AS test;" 2>&1)
CONNECTION_RESULT=$?
set -e  # Re-enable exit on error

bashio::log.info "Connection attempt finished with exit code: ${CONNECTION_RESULT}"

# Clean up config file
rm -f "${MYSQL_CONFIG}"

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
    bashio::log.info "Testing network connectivity to ${MARIADB_HOST}..."
    if ping -c 1 -W 2 "${MARIADB_HOST}" &>/dev/null; then
        bashio::log.info "✓ Host ${MARIADB_HOST} is reachable via ping"
    else
        bashio::log.fatal "✗ Host ${MARIADB_HOST} is NOT reachable via ping!"
    fi
    
    bashio::log.info "Testing port 3306 connectivity..."
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
bashio::log.info "Query result: ${CONNECTION_TEST}"

# Set data directory
DATA_DIR="/share/nextfiles"
NEXTCLOUD_DIR="/var/www/nextcloud"

# Configure PATH for apache user
export PATH="/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

# Find PHP binary
PHP_BIN=$(command -v php || true)

if [ -z "$PHP_BIN" ]; then
    bashio::log.fatal "PHP not found in PATH! Make sure php is installed in the container."
    exit 1
fi

bashio::log.info "Using PHP binary: ${PHP_BIN}"

# Create data directories
bashio::log.info "Setting up data directory: ${DATA_DIR}"
mkdir -p "${DATA_DIR}/data"
mkdir -p "${DATA_DIR}/config"
mkdir -p "${DATA_DIR}/apps"

# Ensure apache user exists
if ! id apache &>/dev/null; then
    addgroup -g 48 apache
    adduser -D -u 48 -G apache -s /sbin/nologin apache
fi

# Fix permissions for /share mount
bashio::log.info "Fixing permissions on /share/nextfiles..."
chown -R apache:apache "${DATA_DIR}"
chmod -R 755 "${DATA_DIR}"

# Update PHP settings
bashio::log.info "Updating PHP configuration..."
sed -i "s|memory_limit = .*|memory_limit = ${MEMORY_LIMIT}|g" /etc/php83/php.ini
sed -i "s|upload_max_filesize = .*|upload_max_filesize = ${MAX_UPLOAD}|g" /etc/php83/php.ini
sed -i "s|post_max_size = .*|post_max_size = ${MAX_UPLOAD}|g" /etc/php83/php.ini

# First installation check
if [ ! -f "${DATA_DIR}/config/config.php" ]; then
    bashio::log.info "First run detected. Installing Nextcloud with MariaDB..."
    
    if [ -z "${ADMIN_PASSWORD}" ]; then
        bashio::log.fatal "Admin password is not set! Please configure it in the add-on options."
        exit 1
    fi

    cd "${NEXTCLOUD_DIR}"

    bashio::log.info "Installing Nextcloud with MariaDB database..."
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

    # Move config to persistent storage
    cp "${NEXTCLOUD_DIR}/config/config.php" "${DATA_DIR}/config/config.php"
    rm -f "${NEXTCLOUD_DIR}/config/config.php"
    ln -sf "${DATA_DIR}/config/config.php" "${NEXTCLOUD_DIR}/config/config.php"

else
    bashio::log.info "Existing installation detected. Linking config..."
    rm -f "${NEXTCLOUD_DIR}/config/config.php"
    ln -sf "${DATA_DIR}/config/config.php" "${NEXTCLOUD_DIR}/config/config.php"

    # Enable maintenance mode
    bashio::log.info "Enabling maintenance mode for safe upgrade..."
    su -s /bin/bash apache -c \
        "${PHP_BIN} ${NEXTCLOUD_DIR}/occ maintenance:mode --on" \
        2>/dev/null || true
fi

# Fix permissions for config directory
bashio::log.info "Fixing permissions for Nextcloud config directory..."
chown -R apache:apache "${DATA_DIR}/config"
chmod -R 755 "${DATA_DIR}/config"

# Fix permissions also on Nextcloud's config dir
chown apache:apache "${NEXTCLOUD_DIR}/config"
chmod 755 "${NEXTCLOUD_DIR}/config"

# Create updater backup folder to avoid warnings
bashio::log.info "Checking for updater backup folder..."
APPDATA_FOLDER=$(find "${DATA_DIR}/data" -maxdepth 1 -type d -name "appdata_oc*" 2>/dev/null | head -n 1)

if [ -n "$APPDATA_FOLDER" ]; then
    # Extract the unique code (e.g., oc7393aorzg2)
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

# --- SBLOCCO CIRCLES E CONFIGURAZIONE APCu ---
bashio::log.info "Cleaning up old locks and configuring APCu..."

# Rimuove il blocco di Circles (Risolve l'errore MigrationException)
su -s /bin/bash apache -c "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:app:delete circles migration_lock" 2>/dev/null || true

# Configure APCu as local cache
bashio::log.info "Configuring APCu as local memory cache..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set memcache.local --type=string --value='\\OC\\Memcache\\APCu'" \
    2>/dev/null || true

# --- CONFIGURAZIONE REDIS (Inizio blocco IF) ---
if [[ -n "${REDIS_HOST}" ]] && nc -z "${REDIS_HOST}" "${REDIS_PORT}" 2>/dev/null; then
    bashio::log.info "=========================================="
    bashio::log.info "Redis detected at ${REDIS_HOST}:${REDIS_PORT}"
    bashio::log.info "=========================================="
    
    # Cancelliamo la vecchia configurazione per evitare errori WRONGPASS/NOAUTH
    su -s /bin/bash apache -c "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:delete redis" 2>/dev/null || true
    
    bashio::log.info "Configuring Redis for file locking and cache..."
    su -s /bin/bash apache -c \
        "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set memcache.locking --type=string --value='\\OC\\Memcache\\Redis'" \
        2>/dev/null || true
    
    su -s /bin/bash apache -c \
        "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set memcache.distributed --type=string --value='\\OC\\Memcache\\Redis'" \
        2>/dev/null || true
    
    bashio::log.info "Setting Redis connection parameters..."
    su -s /bin/bash apache -c \
        "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set redis host --type=string --value='${REDIS_HOST}'" \
        2>/dev/null || true
    
    su -s /bin/bash apache -c \
        "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set redis port --type=integer --value='${REDIS_PORT}'" \
        2>/dev/null || true
    
    if [[ -n "${REDIS_PASSWORD}" ]]; then
        bashio::log.info "Setting Redis password..."
        su -s /bin/bash apache -c \
            "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set redis password --type=string --value='${REDIS_PASSWORD}'" \
            2>/dev/null || true
    fi
    
    bashio::log.info "✓ Redis integration completed!"

# --- (Raggiungibilità Fallita) ---
elif [[ -n "${REDIS_HOST}" ]]; then
    bashio::log.warning "Redis configured but not reachable at ${REDIS_HOST}:${REDIS_PORT}"
    bashio::log.warning "Continuing without Redis - only APCu cache will be used"

# --- (Nessun Redis configurato) ---
else
    bashio::log.info "No Redis configured - using only APCu for local cache"
fi

# Configure trusted domains
bashio::log.info "Configuring trusted domains..."

# Delete existing to reset
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:delete trusted_domains" \
    2>/dev/null || true

DOMAIN_COUNT=$(bashio::config 'trusted_domains | length')
bashio::log.info "Found ${DOMAIN_COUNT} trusted domains in configuration"

for i in $(seq 0 $((DOMAIN_COUNT - 1))); do
    DOMAIN=$(bashio::config "trusted_domains[${i}]")
    if [[ -n "${DOMAIN}" ]]; then
        bashio::log.info "Adding trusted domain [${i}]: ${DOMAIN}"
        su -s /bin/bash apache -c \
            "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set trusted_domains ${i} --value='${DOMAIN}'" \
            2>/dev/null || true
    fi
done

# Configure trusted proxies
bashio::log.info "Configuring trusted proxies..."

# First, delete existing trusted_proxies to reset
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:delete trusted_proxies" \
    2>/dev/null || true

# Get count of trusted proxies
PROXY_COUNT=$(bashio::config 'trusted_proxies | length')
bashio::log.info "Found ${PROXY_COUNT} trusted proxies in configuration"

# Add each proxy
for i in $(seq 0 $((PROXY_COUNT - 1))); do
    PROXY=$(bashio::config "trusted_proxies[${i}]")
    if [[ -n "${PROXY}" ]]; then
        bashio::log.info "Adding trusted proxy [${i}]: ${PROXY}"
        su -s /bin/bash apache -c \
            "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set trusted_proxies ${i} --value='${PROXY}'" \
            2>/dev/null || true
    fi
done

# Set overwrite settings
FIRST_DOMAIN=$(bashio::config 'trusted_domains | .[0]')

bashio::log.info "Configuring overwrite settings for reverse proxy..."

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set overwritehost --value='${FIRST_DOMAIN}'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set overwriteprotocol --value='https'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set overwrite.cli.url --value='https://${FIRST_DOMAIN}/nextfiles'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set overwritewebroot --value='/nextfiles'" \
    2>/dev/null || true

# Fix reverse proxy headers security
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set forwarded_for_headers 0 --value='HTTP_X_FORWARDED_FOR'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set forwarded_for_headers 1 --value='HTTP_X_REAL_IP'" \
    2>/dev/null || true

# Set default phone region (Italy)
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set default_phone_region --value='IT'" \
    2>/dev/null || true

# Set maintenance window (3 AM)
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set maintenance_window_start --value='3' --type=integer" \
    2>/dev/null || true

# Add missing database indices
bashio::log.info "Adding missing database indices..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ db:add-missing-indices" \
    2>/dev/null || true

# Convert database columns to big int (important for MariaDB)
bashio::log.info "Converting database columns to big int..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ db:convert-filecache-bigint --no-interaction" \
    2>/dev/null || true

# Run MIME type migrations (Nextcloud 31+)
bashio::log.info "Running MIME type migrations..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ maintenance:repair --include-expensive" \
    2>/dev/null || true

# Disable maintenance mode
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ maintenance:mode --off" \
    2>/dev/null || true

# Final permissions
chown -R apache:apache "${NEXTCLOUD_DIR}"
chown -R apache:apache "${DATA_DIR}"

# Configure Nextcloud to use cron for background jobs
bashio::log.info "Configuring Nextcloud to use cron..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ background:cron" \
    2>/dev/null || true

# Verify crontab is configured
bashio::log.info "Verifying crontab configuration..."
if [ -f /etc/crontabs/root ]; then
    bashio::log.info "Crontab found:"
    cat /etc/crontabs/root
else
    bashio::log.error "Crontab file not found!"
fi

# Start cron daemon in foreground with logging level 2
bashio::log.info "Starting cron daemon..."
crond -f -l 2 &

# Give cron a moment to start
sleep 2

# Verify crond is running
if pgrep crond > /dev/null; then
    bashio::log.info "Cron daemon is running (PID: $(pgrep crond))"
else
    bashio::log.error "Cron daemon failed to start!"
fi

bashio::log.info "Nextfiles is ready! Using MariaDB database with APCu cache."
if [[ -n "${REDIS_HOST}" ]] && nc -z "${REDIS_HOST}" "${REDIS_PORT}" 2>/dev/null; then
    bashio::log.info "Redis integration active for file locking and distributed cache."
fi
bashio::log.info "Starting Apache web server..."
exec httpd -D FOREGROUND
