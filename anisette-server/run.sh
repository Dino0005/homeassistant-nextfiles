#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Anisette v3 Server – entrypoint per l'add-on Home Assistant
# ---------------------------------------------------------------------------
# Il server cerca le librerie Apple (libstoreservicescore.so, libCoreADI.so)
# in $HOME/.config/anisette-v3/lib/.
#
# Mappiamo HOME su /share in modo che il path diventi:
#   /share/.config/anisette-v3/lib/
# che sopravvive ai rebuild del container grazie al volume /share di HA.
#
# Se /share/anisette-v3/lib/ contiene già i file (ad es. copiati via Samba
# da un'installazione precedente), vengono linkati al percorso atteso.
# ---------------------------------------------------------------------------

CONFIG_DIR="/share/.config/anisette-v3/lib"
SHARE_LIB_DIR="/share/anisette-v3/lib"

echo "[anisette-v3] Avvio Anisette v3 Server..."
echo "[anisette-v3] Directory dati persistente: ${CONFIG_DIR}"

# Crea le directory necessarie
mkdir -p "${CONFIG_DIR}"
mkdir -p "${SHARE_LIB_DIR}"

# Se l'utente ha pre-popolato /share/anisette-v3/lib/ (tramite Samba),
# crea symlink nella directory attesa dal server.
if [ -n "$(ls -A "${SHARE_LIB_DIR}" 2>/dev/null)" ]; then
    echo "[anisette-v3] File trovati in ${SHARE_LIB_DIR}, collegamento al percorso di configurazione..."
    for f in "${SHARE_LIB_DIR}"/*; do
        fname="$(basename "$f")"
        target="${CONFIG_DIR}/${fname}"
        if [ ! -e "${target}" ]; then
            ln -sf "$f" "${target}"
            echo "[anisette-v3]   → ${fname}"
        fi
    done
fi

# Punta HOME su /share così il server trova $HOME/.config/anisette-v3/lib/
export HOME="/share"

echo "[anisette-v3] Server in ascolto sulla porta 6969..."
exec /opt/anisette-v3-server
