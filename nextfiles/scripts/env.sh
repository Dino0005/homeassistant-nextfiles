#!/bin/bash
# =============================================================================
# env.sh — Variabili condivise tra tutti gli script
# Sourced da run.sh DOPO la lettura di options.json
# =============================================================================

export CONFIG_FILE="/data/options.json"
export DATA_DIR="/share/nextfiles"
export NEXTCLOUD_DIR="/var/www/nextcloud"
export MYSQL_CONFIG="/tmp/mysql_client.cnf"

export PATH="/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin:$PATH"
