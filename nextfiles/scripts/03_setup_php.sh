#!/bin/bash
# =============================================================================
# 03_setup_php.sh — Rilevamento PHP e aggiornamento php.ini a runtime
# =============================================================================
set -e
source /usr/lib/bashio/bashio.sh
source /scripts/env.sh

# ---------------------------------------------------------------------------
# Rilevamento binario PHP
# ---------------------------------------------------------------------------
export PHP_BIN=$(command -v php || true)

if [ -z "$PHP_BIN" ]; then
    bashio::log.fatal "PHP not found in PATH! Make sure php is installed in the container."
    exit 1
fi
bashio::log.info "Using PHP binary: ${PHP_BIN}"

# ---------------------------------------------------------------------------
# Rilevamento php.ini (compatibile con future versioni PHP)
# ---------------------------------------------------------------------------
bashio::log.info "Detecting PHP configuration file..."
PHP_INI=$(php --ini | grep "Loaded Configuration File" | cut -d: -f2 | xargs)

if [ -z "${PHP_INI}" ] || [ ! -f "${PHP_INI}" ]; then
    bashio::log.error "Could not detect php.ini location!"
    bashio::log.error "Output from 'php --ini':"
    php --ini
    exit 1
fi

bashio::log.info "PHP ini file: ${PHP_INI}"

# ---------------------------------------------------------------------------
# Applicazione parametri runtime (da options.json)
# ---------------------------------------------------------------------------
bashio::log.info "Updating PHP configuration (memory: ${MEMORY_LIMIT}, upload: ${MAX_UPLOAD})..."
sed -i "s|memory_limit = .*|memory_limit = ${MEMORY_LIMIT}|g"             "${PHP_INI}"
sed -i "s|upload_max_filesize = .*|upload_max_filesize = ${MAX_UPLOAD}|g" "${PHP_INI}"
sed -i "s|post_max_size = .*|post_max_size = ${MAX_UPLOAD}|g"             "${PHP_INI}"

bashio::log.info "✓ PHP configuration updated"
