#!/bin/bash
# =============================================================================
# 06_finalize.sh — Operazioni finali
#   - Indici DB e bigint
#   - Fix Circles (disabilitazione + pulizia job)
#   - Pulizia chiavi DAV obsolete
#   - maintenance:repair
#   - Configurazione apps_paths in config.php
#   - Permessi finali + ripristino sessioni
#   - Symlink di compatibilità apps2 → apps
#   - Avvio cron
# =============================================================================
set -e
source /usr/lib/bashio/bashio.sh
source /scripts/env.sh

occ() {
    su -s /bin/bash apache -c "${PHP_BIN} ${NEXTCLOUD_DIR}/occ $*" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Indici DB e conversione bigint
# ---------------------------------------------------------------------------
bashio::log.info "Adding missing database indices..."
occ "db:add-missing-indices"

bashio::log.info "Converting database columns to big int..."
occ "db:convert-filecache-bigint --no-interaction"

# ---------------------------------------------------------------------------
# Fix Circles — disabilitazione definitiva
# ---------------------------------------------------------------------------
bashio::log.info "Disabling Circles app to prevent persistent migration errors..."

# 1. Disabilita l'app
occ "app:disable circles"

# 2. Rimuovi job appesi in MariaDB
${MYSQL_CMD} --defaults-extra-file="${MYSQL_CONFIG}" \
    -e "DELETE FROM ${MARIADB_DATABASE}.oc_jobs WHERE class LIKE '%Circles%';" \
    2>/dev/null || true

# 3. Esegui repair (velocissimo ora che Circles è disabilitato)
bashio::log.info "Running maintenance repair..."
occ "maintenance:repair --include-expensive --no-interaction"

# 4. Pulizia lock di migrazione DOPO il repair
bashio::log.info "Cleaning up Circles migration locks..."
occ "config:app:delete circles migration_lock"
occ "config:app:delete circles migration_22_0_0"
occ "config:app:delete circles migration_22_0_1"

# ---------------------------------------------------------------------------
# Pulizia chiavi DAV obsolete (NC33 config lexicon)
# ---------------------------------------------------------------------------
bashio::log.info "Cleaning up obsolete DAV config keys..."
${MYSQL_CMD} --defaults-extra-file="${MYSQL_CONFIG}" -e \
    "DELETE FROM ${MARIADB_DATABASE}.oc_appconfig
     WHERE appid='dav'
       AND configkey IN (
         'regeneratedBirthdayCalendarsForYearFix',
         'buildCalendarSearchIndex',
         'builtSocialSearchIndex',
         'system_addressbook_limit',
         'buildCalendarReminderIndex',
         'hide_absence_settings',
         'enableCalendarFederation',
         'sendInvitations',
         'needs_system_address_book_sync'
       );" \
    2>/dev/null || true

# ---------------------------------------------------------------------------
# Disattiva maintenance mode
# ---------------------------------------------------------------------------
occ "maintenance:mode --off"

# ---------------------------------------------------------------------------
# Configurazione apps_paths in config.php
# ---------------------------------------------------------------------------
bashio::log.info "Configuring custom apps directory (apps2) in config.php..."

cat > /tmp/update_apps_paths.php << EOFPHP
<?php
\$configFile = '${DATA_DIR}/config/config.php';
if (file_exists(\$configFile)) {
    include \$configFile;
    \$CONFIG['apps_paths'] = [
        [
            'path'     => '/var/www/nextcloud/apps2',
            'url'      => '/apps2',
            'writable' => true,
        ],
        [
            'path'     => '/var/www/nextcloud/apps',
            'url'      => '/apps',
            'writable' => false,
        ],
    ];
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

# ---------------------------------------------------------------------------
# Permessi finali
# ---------------------------------------------------------------------------
bashio::log.info "Applying final permissions..."
chown -R apache:apache "${NEXTCLOUD_DIR}"
chown -R apache:apache "${DATA_DIR}"

# Ripristina permessi sicuri (600) sui file di sessione esistenti
if compgen -G "${DATA_DIR}/sessions/sess_*" > /dev/null 2>&1; then
    chmod 600 "${DATA_DIR}/sessions"/sess_* 2>/dev/null || true
    bashio::log.info "✓ Restored secure permissions (600) for session files"
fi

# ---------------------------------------------------------------------------
# Symlink di compatibilità apps2 → apps
# (per app con path hardcoded su /var/www/nextcloud/apps)
# ---------------------------------------------------------------------------
bashio::log.info "Creating compatibility symlinks for apps2 apps..."
if [ -d "${NEXTCLOUD_DIR}/apps2" ]; then
    for app_dir in "${NEXTCLOUD_DIR}/apps2"/*; do
        if [ -d "$app_dir" ]; then
            app_name=$(basename "$app_dir")
            if [ ! -e "${NEXTCLOUD_DIR}/apps/$app_name" ]; then
                ln -sf "${NEXTCLOUD_DIR}/apps2/$app_name" "${NEXTCLOUD_DIR}/apps/$app_name"
            fi
        fi
    done
    bashio::log.info "✓ Compatibility symlinks created for apps2 apps"
fi

# ---------------------------------------------------------------------------
# Background jobs: modalità cron
# ---------------------------------------------------------------------------
bashio::log.info "Configuring Nextcloud to use cron for background jobs..."
occ "background:cron"

# ---------------------------------------------------------------------------
# Verifica e avvio cron daemon
# ---------------------------------------------------------------------------
bashio::log.info "Verifying crontab configuration..."
if [ -f /etc/crontabs/root ]; then
    bashio::log.info "Crontab found:"
    cat /etc/crontabs/root
else
    bashio::log.error "Crontab file not found!"
fi

bashio::log.info "Starting cron daemon..."
crond -f -l 2 &
sleep 2

if pgrep crond > /dev/null; then
    bashio::log.info "✓ Cron daemon is running (PID: $(pgrep crond))"
else
    bashio::log.error "Cron daemon failed to start!"
fi

# ---------------------------------------------------------------------------
# Pulizia file temporanei
# ---------------------------------------------------------------------------
bashio::log.info "Cleaning up temporary files..."
rm -f "${MYSQL_CONFIG}"

bashio::log.info "✓ Finalize complete"
