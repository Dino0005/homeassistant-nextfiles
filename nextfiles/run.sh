#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Starting Nextfiles setup..."

# Get configuration
ADMIN_USER=$(bashio::config 'admin_user')
ADMIN_PASSWORD=$(bashio::config 'admin_password')
MAX_UPLOAD=$(bashio::config 'max_upload_size')
MEMORY_LIMIT=$(bashio::config 'memory_limit')

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

# Setup custom_apps directory for persistent app storage
bashio::log.info "Setting up custom_apps directory..."
if [ ! -L "/var/www/nextcloud/custom_apps" ]; then
    # Remove default directory if exists
    rm -rf /var/www/nextcloud/custom_apps
    # Create symlink to persistent storage
    ln -sf "${DATA_DIR}/apps" /var/www/nextcloud/custom_apps
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
    bashio::log.info "First run detected. Installing Nextcloud..."
    
    if [ -z "${ADMIN_PASSWORD}" ]; then
        bashio::log.fatal "Admin password is not set! Please configure it in the add-on options."
        exit 1
    fi

    cd "${NEXTCLOUD_DIR}"

    su -s /bin/bash apache -c \
        "${PHP_BIN} occ maintenance:install \
        --database='sqlite' \
        --database-name='nextcloud' \
        --data-dir='${DATA_DIR}/data' \
        --admin-user='${ADMIN_USER}' \
        --admin-pass='${ADMIN_PASSWORD}'" \
        || { bashio::log.fatal 'Error during Nextcloud installation'; exit 1; }

    bashio::log.info "Nextcloud installed successfully!"

    # Move config to persistent storage
    cp "${NEXTCLOUD_DIR}/config/config.php" "${DATA_DIR}/config/config.php"
    rm -f "${NEXTCLOUD_DIR}/config/config.php"
    ln -sf "${DATA_DIR}/config/config.php" "${NEXTCLOUD_DIR}/config/config.php"

else
    bashio::log.info "Existing installation detected. Linking config..."
    rm -f "${NEXTCLOUD_DIR}/config/config.php"
    ln -sf "${DATA_DIR}/config/config.php" "${NEXTCLOUD_DIR}/config/config.php"
fi

# Fix permissions for config directory
bashio::log.info "Fixing permissions for Nextcloud config directory..."
chown -R apache:apache "${DATA_DIR}/config"
chmod -R 755 "${DATA_DIR}/config"

# Fix permissions also on Nextcloud's config dir
chown apache:apache "${NEXTCLOUD_DIR}/config"
chmod 755 "${NEXTCLOUD_DIR}/config"

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

# Enable custom_apps directory
bashio::log.info "Configuring custom apps directory..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set apps_paths 1 path --value='/var/www/nextcloud/custom_apps'" \
    2>/dev/null || true
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set apps_paths 1 url --value='/custom_apps'" \
    2>/dev/null || true
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ config:system:set apps_paths 1 writable --value=true --type=boolean" \
    2>/dev/null || true

# Add missing database indices
bashio::log.info "Adding missing database indices..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ db:add-missing-indices" \
    2>/dev/null || true

# Run MIME type migrations (Nextcloud 31+)
bashio::log.info "Running MIME type migrations..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ maintenance:repair --include-expensive" \
    2>/dev/null || true

# Clear frontend caches (fix JS/CSS issues)
bashio::log.info "Clearing frontend caches..."
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ maintenance:repair" \
    2>/dev/null || true

# Disable maintenance mode
su -s /bin/bash apache -c \
    "${PHP_BIN} ${NEXTCLOUD_DIR}/occ maintenance:mode --off" \
    2>/dev/null || true

# Final permissions
chown -R apache:apache "${NEXTCLOUD_DIR}"
chown -R apache:apache "${DATA_DIR}"

bashio::log.info "Starting Apache web server..."
exec httpd -D FOREGROUND
