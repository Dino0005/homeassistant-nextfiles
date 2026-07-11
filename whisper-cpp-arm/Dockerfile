ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:latest
FROM ${BUILD_FROM}

# Se non pubblichi tramite la GitHub Action ufficiale del builder HA,
# queste label vanno dichiarate a mano: il Supervisor le legge per
# riconoscere l'immagine come add-on valido.
LABEL \
    io.hass.version="1.1.5" \
    io.hass.type="app" \
    io.hass.arch="aarch64"

ENV LANG=C.UTF-8

# Versione di whisper.cpp pinnata: whisper.cpp ha abbandonato il vecchio
# Makefile/binario "main" in favore di CMake, con binari rinominati
# (es. "whisper-cli") in build/bin/. Pinnare la versione evita che un
# futuro cambiamento upstream rompa di nuovo l'add-on senza preavviso.
ARG WHISPER_CPP_VERSION=v1.9.1

# Dipendenze di sistema e compilazione
RUN apk add --no-cache \
    build-base \
    git \
    python3 \
    py3-pip \
    cmake \
    curl

# Clona e compila whisper.cpp nativamente con CMake.
# Su architettura aarch64, whisper.cpp rileva ed abilita da solo il
# supporto ARM NEON: non servono flag manuali (a differenza di AVX/AVX2
# su x86, che qui semplicemente non esistono).
WORKDIR /build
RUN git clone --branch "${WHISPER_CPP_VERSION}" --depth 1 \
        https://github.com/ggml-org/whisper.cpp.git \
    && cd whisper.cpp \
    && cmake -B build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build --config Release -j"$(nproc)"

# Libreria wyoming per l'integrazione con Home Assistant
RUN pip3 install --no-cache-dir --break-system-packages wyoming==1.6.0

WORKDIR /share
COPY run.sh /run.sh
COPY wyoming_whisper_cpp.py /wyoming_whisper_cpp.py
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
