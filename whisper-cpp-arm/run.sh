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

bashio::log.info "Avvio del ponte Wyoming verso whisper.cpp (lingua di default: ${LANGUAGE})..."

python3 /wyoming_whisper_cpp.py \
    --whisper-path "$WHISPER_BIN" \
    --model-path "$MODEL_PATH" \
    --language "$LANGUAGE" \
    --uri "tcp://0.0.0.0:10300"
