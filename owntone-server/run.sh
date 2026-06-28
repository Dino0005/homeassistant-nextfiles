#!/usr/bin/with-contenv bashio

bashio::log.info "Preparazione dell'ambiente OwnTone..."

# ─── 1. Avvia D-Bus (richiesto da Avahi) ─────────────────────────────────────
mkdir -p /run/dbus
# Rimuovi il pid file residuo da eventuali riavvii
rm -f /run/dbus/dbus.pid
dbus-daemon --system --fork

# ─── 2. Avvia Avahi per il discovery AirPlay/Chromecast ──────────────────────
mkdir -p /run/avahi-daemon
chown avahi:avahi /run/avahi-daemon
avahi-daemon --no-chroot -D

# ─── 3. Prepara la directory del database ────────────────────────────────────
mkdir -p /var/cache/owntone
chown -R owntone:owntone /var/cache/owntone

# ─── 4. Prepara il file di configurazione ────────────────────────────────────
CONF="/etc/owntone/owntone.conf"
CONF_EXAMPLE="/usr/share/doc/owntone/owntone.conf"

# Se il file di configurazione non esiste, crea la directory e copialo dall'esempio
if [ ! -f "${CONF}" ]; then
    bashio::log.info "File di configurazione non trovato, creazione da template..."
    mkdir -p /etc/owntone
    cp "${CONF_EXAMPLE}" "${CONF}"
fi

# Adatta la configurazione ai percorsi HA (solo se non già modificata)
if ! grep -q '/var/cache/owntone/database.db' "${CONF}"; then
    bashio::log.info "Configurazione di owntone.conf per Home Assistant..."
    sed -i \
        -e 's|.*db_path = .*|\tdb_path = "/var/cache/owntone/database.db"|' \
        -e 's|.*db_backup_path = .*|\tdb_backup_path = "/var/cache/owntone/database.bak"|' \
        -e 's|.*cache_path = .*|\tcache_path = "/var/cache/owntone/cache.db"|' \
        -e 's|.*directories = {.*}.*|\tdirectories = { "/media" }|' \
        -e 's|.*trusted_networks = {.*}.*|\ttrusted_networks = { "any" }|' \
        "${CONF}"
fi

# ─── 5. Avvia OwnTone in foreground come utente owntone ──────────────────────
bashio::log.info "Avvio di OwnTone Server (musica da /media)..."
exec su-exec owntone owntone -f -c "${CONF}"
