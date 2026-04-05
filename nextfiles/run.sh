#!/usr/bin/with-contenv /bin/bash
# shellcheck shell=bash
set -e

# Load bashio library
source /usr/lib/bashio/bashio.sh

bashio::log.info "Starting Nextfiles setup..."

# Read configuration from /data/options.json (HA provides this file automatically)
CONFIG_FILE="/data/options.json"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "[FATAL] Configuration file /data/options.json not found!"
    exit 1
fi

bashio::log.info "Reading configuration from ${CONFIG_FILE}"

# Get configuration
ADMIN_USER=$(jq -r '.admin_user // "admin"' ${CONFIG_FILE})
ADMIN_PASSWORD=$(jq -r '.admin_password // ""' ${CONFIG_FILE})
MAX_UPLOAD=$(jq -r '.max_upload_size // "512M"' ${CONFIG_FILE})
MEMORY_LIMIT=$(jq -r '.memory_limit // "512M"' ${CONFIG_FILE})
DEFAULT_PHONE_REGION=$(jq -r '.default_phone_region // "IT"' ${CONFIG_FILE})

# Get Redis configuration (optional)
REDIS_HOST=$(jq -r '.redis_host // ""' ${CONFIG_FILE})
REDIS_PORT=$(jq -r '.redis_port // 6379' ${CONFIG_FILE})
REDIS_PASSWORD=$(jq -r '.redis_password // ""' ${CONFIG_FILE})

# Get MariaDB configuration
MARIADB_HOST=$(jq -r '.mariadb_host // "core-mariadb"' ${CONFIG_FILE})
MARIADB_DATABASE=$(jq -r '.mariadb_database // "nextcloud"' ${CONFIG_FILE})
MARIADB_USERNAME=$(jq -r '.mariadb_username // "nextcloud"' ${CONFIG_FILE})
MARIADB_PASSWORD=$(jq -r '.mariadb_password // ""' ${CONFIG_FILE})

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

# Don't remove config file yet - we'll reuse it later for cleanup
# Config file will be removed at the end of the script

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
mkdir -p "${DATA_DIR}/apps_custom"
# Temp directory for Nextcloud (necessary to upgrade to NC33+)
mkdir -p "${DATA_DIR}/tmp"
chown apache:apache "${DATA_DIR}/tmp"

# Ensure apache user exists FIRST (needed for chown commands below)
if ! id apache &>/dev/null; then
    bashio::log.info "Creating apache user..."
    addgroup -g 48 apache
    adduser -D -u 48 -G apache -s /sbin/nologin apache
fi

# Fix permissions for /share mount (apply general 755 permissions)
bashio::log.info "Fixing permissions on ${DATA_DIR}..."
chown -R apache:apache "${DATA_DIR}"
chmod -R 755 "${DATA_DIR}"

# Setup persistent session directory AFTER general permissions
# This ensures the special 1777 permissions are not overwritten
bashio::log.info "Setting up persistent session directory..."
mkdir -p "${DATA_DIR}/sessions"
chown apache:apache "${DATA_DIR}/sessions"
chmod 1777 "${DATA_DIR}/sessions"

# Verify session directory permissions
PERMS=$(stat -c "%a" "${DATA_DIR}/sessions" 2>/dev/null || echo "0")
if [ "$PERMS" != "1777" ]; then
    bashio::log.warning "Session directory permissions incorrect ($PERMS), fixing..."
    chmod 1777 "${DATA_DIR}/sessions"
fi

bashio::log.info "✓ Session directory configured at ${DATA_DIR}/sessions (perms: 1777)"

# Create symlink for custom apps directory
bashio::log.info "Setting up custom apps directory..."
if [ ! -L "${NEXTCLOUD_DIR}/apps2" ]; then
    rm -rf "${NEXTCLOUD_DIR}/apps2"
    ln -sf "${DATA_DIR}/apps_custom" "${NEXTCLOUD_DIR}/apps2"
fi
chown -R apache:apache "${DATA_DIR}/apps_custom"
bashio::log.info "✓ Custom apps directory linked at /var/www/nextcloud/apps2"

# Update PHP settings (dynamically detect php.ini path for future PHP version compatibility)
bashio::log.info "Detecting PHP configuration file..."
PHP_INI=$(php --ini | grep "Loaded Configuration File" | cut -d: -f2 | xargs)

if [ -z "${PHP_INI}" ] || [ ! -f "${PHP_INI}" ]; then
    bashio::log.error "Could not detect php.ini location!"
    bashio::log.error "Output from 'php --ini':"
    php --ini
    exit 1
fi

bashio::log.info "Updating PHP configuration..."
bashio::log.info "PHP ini file: ${PHP_INI}"

sed -i "s|memory_limit = .*|memory_limit = ${MEMORY_LIMIT}|g" "${PHP_INI}"
sed -i "s|upload_max_filesize = .*|upload_max_filesize = ${MAX_UPLOAD}|g" "${PHP_INI}"
sed -i "s|post_max_size = .*|post_max_size = ${MAX_UPLOAD}|g" "${PHP_INI}"

bashio::log.info "✓ PHP configuration updated (memory: ${MEMORY_LIMIT}, upload: ${MAX_UPLOAD})"

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

# Configure APCu as local cache
bashio::log.info "Configuring APCu as local memory cache..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set memcache.local --type=string --value='\\OC\\Memcache\\APCu'" \
    2>/dev/null || true

# Configure preview providers for better thumbnails
bashio::log.info "Configuring preview providers (ImageMagick + FFmpeg)..."

# Enable ImageMagick
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 0 --value='OC\\Preview\\PNG'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 1 --value='OC\\Preview\\JPEG'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 2 --value='OC\\Preview\\GIF'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 3 --value='OC\\Preview\\BMP'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 4 --value='OC\\Preview\\XBitmap'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 5 --value='OC\\Preview\\MP3'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 6 --value='OC\\Preview\\TXT'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 7 --value='OC\\Preview\\MarkDown'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 8 --value='OC\\Preview\\PDF'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 9 --value='OC\\Preview\\SVG'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 10 --value='OC\\Preview\\Font'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 11 --value='OC\\Preview\\HEIC'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 12 --value='OC\\Preview\\Movie'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 13 --value='OC\\Preview\\MSOfficeDoc'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 14 --value='OC\\Preview\\MSOffice2003'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 15 --value='OC\\Preview\\MSOffice2007'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 16 --value='OC\\Preview\\OpenDocument'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 17 --value='OC\\Preview\\Krita'" \
    2>/dev/null || true

# Note: OC\Preview\Imaginary removed - requires external Imaginary server

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set enabledPreviewProviders 18 --value='OC\\Preview\\Image'" \
    2>/dev/null || true

bashio::log.info "✓ Preview providers configured!"

# Clean up Circles migration lock BEFORE repair (prevents errors during repair)
bashio::log.info "Cleaning up Circles migration lock before repair..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:app:delete circles migration_lock" \
    2>/dev/null || true

# Configure Redis if available
if [[ -n "${REDIS_HOST}" ]] && nc -z "${REDIS_HOST}" "${REDIS_PORT}" 2>/dev/null; then
    bashio::log.info "=========================================="
    bashio::log.info "Redis detected at ${REDIS_HOST}:${REDIS_PORT}"
    bashio::log.info "=========================================="
    
    bashio::log.info "Configuring Redis for file locking..."
    su -s /bin/bash apache -c \
        "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set memcache.locking --type=string --value='\\OC\\Memcache\\Redis'" \
        2>/dev/null || true
    
    bashio::log.info "Configuring Redis for distributed cache..."
    su -s /bin/bash apache -c \
        "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set memcache.distributed --type=string --value='\\OC\\Memcache\\Redis'" \
        2>/dev/null || true
    
    bashio::log.info "Setting Redis connection parameters..."
    
    # Delete any existing redis configuration to start clean
    su -s /bin/bash apache -c \
        "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:delete redis" \
        2>/dev/null || true
    
    # CRITICAL FIX: Initialize redis as array FIRST
    su -s /bin/bash apache -c \
        "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set redis --type=array" \
        2>/dev/null || true
    
    # Now set array keys
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
    else
        bashio::log.info "No Redis password configured"
    fi
    
    bashio::log.info "✓ Redis integration completed!"
elif [[ -n "${REDIS_HOST}" ]]; then
    bashio::log.warning "Redis configured but not reachable at ${REDIS_HOST}:${REDIS_PORT}"
    bashio::log.warning "Continuing without Redis - only APCu cache will be used"
else
    bashio::log.info "No Redis configured - using only APCu for local cache"
fi

# Configure Nextcloud session lifetime for stability (24 hours)
bashio::log.info "Configuring Nextcloud session parameters..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set session_lifetime --value=86400 --type=integer" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set session_keepalive --value=true --type=boolean" \
    2>/dev/null || true

bashio::log.info "✓ Session lifetime set to 24 hours"

# Configure Snowflake ID for Nextcloud 33+ (required for distributed setups)
bashio::log.info "=========================================="
bashio::log.info "Configuring Snowflake ID - Preparation..."
bashio::log.info "=========================================="

# Check if a server_id already exists in config.php so as not to overwrite it
EXISTING_ID=$(su -s /bin/bash apache -c "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:get snowflake.server_id" 2>/dev/null || echo "")

if [ -z "$EXISTING_ID" ]; then
    # If not exists, generate numeric ID based on hostname (0-1023 range for Snowflake)
    NEW_SERVER_ID=$(echo "$(hostname)" | cksum | awk '{print $1 % 1024}')
    su -s /bin/bash apache -c \
        "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set snowflake.server_id --value='${NEW_SERVER_ID}' --type=integer" \
        2>/dev/null || true
    bashio::log.info "✓ New Snowflake ID generated: ${NEW_SERVER_ID}"
else
    bashio::log.info "✓ Snowflake ID already exists: ${EXISTING_ID}"
fi

bashio::log.info "=========================================="

# Configure trusted domains
bashio::log.info "Configuring trusted domains..."

# Delete existing to reset
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:delete trusted_domains" \
    2>/dev/null || true

DOMAIN_COUNT=$(jq -r '.trusted_domains | length' ${CONFIG_FILE})
bashio::log.info "Found ${DOMAIN_COUNT} trusted domains in configuration"

for i in $(seq 0 $((DOMAIN_COUNT - 1))); do
    DOMAIN=$(jq -r ".trusted_domains[${i}]" ${CONFIG_FILE})
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
PROXY_COUNT=$(jq -r '.trusted_proxies | length' ${CONFIG_FILE})
bashio::log.info "Found ${PROXY_COUNT} trusted proxies in configuration"

# Add each proxy
for i in $(seq 0 $((PROXY_COUNT - 1))); do
    PROXY=$(jq -r ".trusted_proxies[${i}]" ${CONFIG_FILE})
    if [[ -n "${PROXY}" ]]; then
        bashio::log.info "Adding trusted proxy [${i}]: ${PROXY}"
        su -s /bin/bash apache -c \
            "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set trusted_proxies ${i} --value='${PROXY}'" \
            2>/dev/null || true
    fi
done

# Set overwrite settings
FIRST_DOMAIN=$(jq -r '.trusted_domains[0] // "localhost"' ${CONFIG_FILE})

bashio::log.info "Configuring overwrite settings for reverse proxy..."

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set overwritehost --value='${FIRST_DOMAIN}'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set overwriteprotocol --value='https'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set overwrite.cli.url --value='https://${FIRST_DOMAIN}'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set overwritewebroot --value='/nextfiles'" \
    2>/dev/null || true

# Set temp directory (necessary to upgrade to NC33+)
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set tempdirectory --value='${DATA_DIR}/tmp'" \
    2>/dev/null || true

# Set server ID
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set serverid --value='1' --type=integer" \
    2>/dev/null || true

# Fix reverse proxy headers security
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set forwarded_for_headers 0 --value='HTTP_X_FORWARDED_FOR'" \
    2>/dev/null || true

su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set forwarded_for_headers 1 --value='HTTP_X_REAL_IP'" \
    2>/dev/null || true

# Set default phone region (configurabile)
bashio::log.info "Setting default phone region to: ${DEFAULT_PHONE_REGION}"
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set default_phone_region --value='${DEFAULT_PHONE_REGION}'" \
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
# --- FIX DEFINITIVO: DISATTIVAZIONE CIRCLES ---
bashio::log.info "Disabling Circles app to prevent persistent migration errors..."

# 1. Disabilitiamo l'app alla radice
su -s /bin/bash apache -c "${PHP_BIN} ${NEXTCLOUD_DIR}/occ app:disable circles" 2>/dev/null || true

# 2. Pulizia MariaDB per rimuovere i job rimasti appesi
${MYSQL_CMD} --defaults-extra-file="${MYSQL_CONFIG}" -e "DELETE FROM ${MARIADB_DATABASE}.oc_jobs WHERE class LIKE '%Circles%';" 2>/dev/null || true

# 3. Eseguiamo il repair (ora sarà velocissimo e senza errori)
bashio::log.info "Running maintenance repair..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ maintenance:repair --include-expensive --no-interaction" \
    2>/dev/null || true

# Clean up Circles migration lock after repair (if it exists)
bashio::log.info "Cleaning up Circles migration locks after repair..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:app:delete circles migration_lock" \
    2>/dev/null || true
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:app:delete circles migration_22_0_0" \
    2>/dev/null || true
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:app:delete circles migration_22_0_1" \
    2>/dev/null || true

# Clean up obsolete DAV config keys (NC33 config lexicon)
bashio::log.info "Cleaning up obsolete DAV config keys..."
${MYSQL_CMD} --defaults-extra-file="${MYSQL_CONFIG}" -e "DELETE FROM ${MARIADB_DATABASE}.oc_appconfig WHERE appid='dav' AND configkey IN ('regeneratedBirthdayCalendarsForYearFix','buildCalendarSearchIndex','builtSocialSearchIndex','system_addressbook_limit','buildCalendarReminderIndex','hide_absence_settings','enableCalendarFederation','sendInvitations','needs_system_address_book_sync','buildCalendarReminderIndex');" 2>/dev/null || true

# Disable maintenance mode
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ maintenance:mode --off" \
    2>/dev/null || true

# Configure apps_paths directly in config.php (avoids "apps directory not found" errors)
bashio::log.info "Configuring custom apps directory (apps2) in config.php..."

# Use PHP to edit config.php directly
cat > /tmp/update_apps_paths.php << EOFPHP
<?php
\$configFile = '${DATA_DIR}/config/config.php';
if (file_exists(\$configFile)) {
    include \$configFile;
    
    // Set apps_paths with apps2 as primary (writable, persistent)
    \$CONFIG['apps_paths'] = [
        [
            'path' => '/var/www/nextcloud/apps2',
            'url' => '/apps2',
            'writable' => true,
        ],
        [
            'path' => '/var/www/nextcloud/apps',
            'url' => '/apps',
            'writable' => false,
        ],
    ];
    
    // Write back to config file
    \$content = "<?php\n\\\$CONFIG = " . var_export(\$CONFIG, true) . ";\n";
    file_put_contents(\$configFile, \$content);
    echo "apps_paths configured successfully\n";
} else {
    echo "Config file not found\n";
    exit(1);
}
EOFPHP

su -s /bin/bash apache -c "${PHP_BIN} /tmp/update_apps_paths.php" && \
    bashio::log.info "✓ Custom apps directory (apps2) configured as primary - new apps will be persistent!" || \
    bashio::log.warning "Failed to configure apps_paths in config.php"

rm -f /tmp/update_apps_paths.php

# Final permissions
chown -R apache:apache "${NEXTCLOUD_DIR}"
chown -R apache:apache "${DATA_DIR}"

# IMPORTANT: Restore session file permissions
if compgen -G "${DATA_DIR}/sessions/sess_*" > /dev/null 2>&1; then
    chmod 600 "${DATA_DIR}/sessions"/sess_* 2>/dev/null || true
    bashio::log.info "✓ Restored secure permissions (600) for session files"
fi

# Create compatibility symlinks for ALL apps in apps2
# This helps apps that have hardcoded paths expecting /var/www/nextcloud/apps
bashio::log.info "Creating compatibility symlinks for apps2 apps..."
if [ -d "${NEXTCLOUD_DIR}/apps2" ]; then
    for app_dir in "${NEXTCLOUD_DIR}/apps2"/*; do
        if [ -d "$app_dir" ]; then
            app_name=$(basename "$app_dir")
            # Only create symlink if app doesn't already exist in /apps
            if [ ! -e "${NEXTCLOUD_DIR}/apps/$app_name" ]; then
                ln -sf "${NEXTCLOUD_DIR}/apps2/$app_name" "${NEXTCLOUD_DIR}/apps/$app_name"
            fi
        fi
    done
    bashio::log.info "✓ Compatibility symlinks created for apps2 apps"
fi

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

# Clean up MySQL config file
bashio::log.info "Cleaning up temporary files..."
rm -f "${MYSQL_CONFIG}"

# Increase stack size to prevent segmentation faults
# Alpine default is 8MB which is too low for Nextcloud recursive operations
# Set to 64MB (65536 KB) to handle deep file trees and app installations
bashio::log.info "Starting Apache with increased stack size (64MB)..."
exec sh -c 'ulimit -s 65536 && exec httpd -D FOREGROUND'
