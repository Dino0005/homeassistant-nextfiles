FROM python:3.11-slim

# Installa jq per leggere options.json
RUN apt-get update && \
    apt-get install -y --no-install-recommends jq && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Installa dipendenze Python
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copia i file dell'applicazione
COPY app.py run.sh ./
COPY static ./static

# Rendi eseguibile lo script di avvio
RUN chmod +x run.sh

# Variabile d'ambiente per output immediato dei log
ENV PYTHONUNBUFFERED=1

# Etichette per Home Assistant
LABEL io.hass.version="0.5.0" \
      io.hass.type="addon" \
      io.hass.arch="armhf|aarch64|amd64|armv7"

CMD ["/app/run.sh"]