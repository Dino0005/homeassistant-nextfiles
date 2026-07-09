#!/usr/bin/with-contenv bashio

# Recupera i valori scelti dall'utente nel pannello di controllo dell'add-on
MODEL=$(bashio::config 'model')
LANGUAGE=$(bashio::config 'language')

# Percorsi interni: modelli nella cartella persistente, binario nel path
# prodotto dalla build CMake (whisper.cpp >= 1.7 non produce più "main")
CONFIG_DIR="/config/addons_config/whisper_cpp_arm"
MODEL_PATH="${CONFIG_DIR}/ggml-${MODEL}.bin"
WHISPER_BIN="/build/whisper.cpp/build/bin/whisper-cli"

mkdir -p "$CONFIG_DIR"

# Scarica il modello GGML da HuggingFace solo se non è già presente
if [ ! -f "$MODEL_PATH" ]; then
    bashio::log.info "Download del modello GGML ${MODEL} in corso..."
    curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${MODEL}.bin" -o "$MODEL_PATH"
fi

# Verifica che il binario esista davvero prima di avviare il bridge:
# se il nome/percorso cambia in una futura versione di whisper.cpp,
# meglio un errore chiaro nei log che un loop di riavvii silenzioso.
if [ ! -x "$WHISPER_BIN" ]; then
    bashio::log.error "Binario whisper-cli non trovato in ${WHISPER_BIN}."
    bashio::log.error "Controlla la versione di whisper.cpp buildata nel Dockerfile."
    exit 1
fi

# --- Controllo di sanità ---
# Genera un breve WAV silenzioso e lo passa a whisper-cli con un timeout.
# Se il binario crasha (es. istruzione illegale non supportata dalla CPU,
# lo stesso problema avuto con l'add-on ufficiale) lo scopriamo subito nei
# log di avvio, invece che dopo aver già selezionato questo servizio come
# motore STT nella pipeline di Assist.
SANITY_WAV="/tmp/whisper_sanity_check.wav"
SANITY_LOG="/tmp/whisper_sanity_check.log"

bashio::log.info "Eseguo un controllo di sanità su whisper-cli prima dell'avvio..."

python3 - "$SANITY_WAV" <<'PYEOF'
import sys
import wave

with wave.open(sys.argv[1], "wb") as f:
    f.setnchannels(1)
    f.setsampwidth(2)
    f.setframerate(16000)
    f.writeframes(b"\x00\x00" * 16000)  # 1 secondo di silenzio
PYEOF

timeout 30 "$WHISPER_BIN" -m "$MODEL_PATH" -f "$SANITY_WAV" -nt -l "$LANGUAGE" > "$SANITY_LOG" 2>&1
SANITY_EXIT=$?

rm -f "$SANITY_WAV"

if [ "$SANITY_EXIT" -eq 124 ]; then
    bashio::log.error "Il controllo di sanità è andato in timeout (30s): whisper-cli potrebbe essere bloccato."
    cat "$SANITY_LOG"
    exit 1
elif [ "$SANITY_EXIT" -ge 128 ]; then
    SIGNAL=$((SANITY_EXIT - 128))
    bashio::log.error "whisper-cli è crashato con segnale ${SIGNAL} durante il controllo di sanità."
    if [ "$SIGNAL" -eq 4 ]; then
        bashio::log.error "Segnale 4 = SIGILL (istruzione illegale): la CPU non supporta un'istruzione richiesta dal binario compilato."
    fi
    bashio::log.error "Log completo del test:"
    cat "$SANITY_LOG"
    exit 1
elif [ "$SANITY_EXIT" -ne 0 ]; then
    bashio::log.warning "whisper-cli è uscito con codice ${SANITY_EXIT} durante il controllo di sanità (può essere normale su audio silenzioso, es. nessun testo prodotto)."
    cat "$SANITY_LOG"
else
    bashio::log.info "Controllo di sanità superato: whisper-cli funziona correttamente."
fi

rm -f "$SANITY_LOG"

bashio::log.info "Avvio del ponte Wyoming verso whisper.cpp (lingua di default: ${LANGUAGE})..."

python3 /wyoming_whisper_cpp.py \
    --whisper-path "$WHISPER_BIN" \
    --model-path "$MODEL_PATH" \
    --language "$LANGUAGE" \
    --uri "tcp://0.0.0.0:10300"
