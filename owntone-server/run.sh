#!/usr/bin/with-contenv bashio

bashio::log.info "Preparazione dell'ambiente OwnTone..."

# ─── 1. Avvia D-Bus (richiesto da Avahi) ─────────────────────────────────────
mkdir -p /run/dbus
rm -f /run/dbus/dbus.pid
dbus-daemon --system --fork

# ─── 2. Avvia Avahi per il discovery AirPlay/Chromecast ──────────────────────
mkdir -p /run/avahi-daemon
chown avahi:avahi /run/avahi-daemon
avahi-daemon --no-chroot -D

# ─── 3. Prepara la directory del database ────────────────────────────────────
mkdir -p /config/owntone/cache
chown -R owntone:owntone /config/owntone/cache

# ─── 4. Prepara directory log scrivibile da owntone ──────────────────────────
mkdir -p /var/log/owntone
chown owntone:owntone /var/log/owntone

# ─── 5. Rimuovi pid file residuo da riavvii precedenti ───────────────────────
rm -f /var/run/owntone.pid /run/owntone.pid /tmp/owntone.pid
killall -9 owntone 2>/dev/null || true

# ─── 6. Adatta owntone.conf ──────────────────────────────────────────────────
CONF="/config/owntone/owntone.conf"
CONF_EXAMPLE="/usr/share/doc/owntone/owntone.conf"

if [ ! -f "${CONF}" ]; then
    bashio::log.info "File di configurazione non trovato, creazione da template..."
    mkdir -p /config/owntone
    cp "${CONF_EXAMPLE}" "${CONF}"
fi

if ! grep -q '/config/owntone/cache/database.db' "${CONF}"; then
    bashio::log.info "Configurazione di owntone.conf per Home Assistant..."
    # Usiamo sed con -E (regex estese) e ancoriamo i parametri con ^ per evitare di
    # colpire righe simili (es. logfile_size o logfile_number)
    sed -i -E \
        -e 's|^#?[[:space:]]*db_path[[:space:]]*=[[:space:]]*.*|db_path = "/config/owntone/cache/database.db"|' \
        -e 's|^#?[[:space:]]*db_backup_path[[:space:]]*=[[:space:]]*.*|db_backup_path = "/config/owntone/cache/database.bak"|' \
        -e 's|^#?[[:space:]]*cache_path[[:space:]]*=[[:space:]]*.*|cache_path = "/config/owntone/cache/cache.db"|' \
        -e 's|^#?[[:space:]]*logfile[[:space:]]*=[[:space:]]*.*|logfile = "/var/log/owntone/owntone.log"|' \
        -e 's|^#?[[:space:]]*directories[[:space:]]*=[[:space:]]*.*|directories = { "/media" }|' \
        -e 's|^#?[[:space:]]*trusted_networks[[:space:]]*=[[:space:]]*.*|trusted_networks = { "any" }|' \
        -e 's|^#?[[:space:]]*type[[:space:]]*=[[:space:]]*"alsa"|type = "disabled"|' \
        -e '/^#airplay_shared \{/,/^#\}/{s|^#airplay_shared \{|airplay_shared \{|; s|^#\}|\}|}' \
        -e 's|^#?[[:space:]]*control_port[[:space:]]*=[[:space:]]*.*|control_port = 3690|' \
        -e 's|^#?[[:space:]]*timing_port[[:space:]]*=[[:space:]]*.*|timing_port = 3691|' \
        "${CONF}"
fi

# ─── 7. Avvia OwnTone in foreground come utente root ─────────────────────────
bashio::log.info "Avvio di OwnTone Server (musica da /media)..."

# Creiamo il file di log e assicuriamoci che root possa scriverci liberamente
touch /var/log/owntone/owntone.log

# Avvio diretto in foreground (eredita i permessi di rete e sblocca la porta 319)
exec owntone -f -c "${CONF}"
