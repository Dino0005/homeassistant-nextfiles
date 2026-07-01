ARG BUILD_FROM=ghcr.io/home-assistant/base:3.24-2026.06.1

# ─── Stage 1: Compilazione ───────────────────────────────────────────────────
FROM ${BUILD_FROM} AS build

# Dipendenze di compilazione
RUN apk add --no-cache \
    alsa-lib-dev \
    autoconf \
    automake \
    avahi-dev \
    bison \
    confuse-dev \
    curl-dev \
    ffmpeg-dev \
    flex \
    g++ \
    gawk \
    gcc \
    gettext-dev \
    git \
    gnutls-dev \
    gperf \
    json-c-dev \
    libevent-dev \
    libgcrypt-dev \
    libplist-dev \
    libsodium-dev \
    libtool \
    libunistring-dev \
    libwebsockets-dev \
    libxml2-dev \
    make \
    npm \
    protobuf-c-dev \
    sqlite-dev

WORKDIR /tmp/source

COPY translations/ /tmp/translations/

RUN git clone -b master https://github.com/owntone/owntone-server.git ./ && \
    mkdir -p web-src/src/i18n && \
    cp /tmp/translations/* web-src/src/i18n/ && \
    cd web-src && npm install && npm run build && cd .. && \
    autoreconf -fvi -I /usr/share/gettext/m4 && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc/owntone \
        --localstatedir=/var \
        --infodir=/usr/share/info \
        --mandir=/usr/share/man \
        --disable-install_systemd \
        --disable-install_user \
        --enable-chromecast \
        --enable-silent-rules && \
    make DESTDIR=/tmp/build install && \
    cd /tmp/build && \
    install -D etc/owntone/owntone.conf usr/share/doc/owntone/owntone.conf && \
    rm -rf var etc

# ─── Stage 2: Runtime ────────────────────────────────────────────────────────
FROM ${BUILD_FROM}

# Copia i binari compilati
COPY --from=build /tmp/build/ /

# Dipendenze runtime
RUN apk add --no-cache \
    avahi \
    confuse \
    dbus \
    ffmpeg \
    gnutls \
    json-c \
    libevent \
    libgcrypt \
    libplist \
    libsodium \
    libunistring \
    libuuid \
    libwebsockets \
    libxml2 \
    protobuf-c \
    sqlite-libs \
    su-exec \
    tzdata && \
    # Crea l'utente owntone
    addgroup -S owntone && \
    adduser -S -G owntone -H -h /var/cache/owntone owntone

# Copia lo script di avvio nella posizione s6-overlay
COPY run.sh /etc/services.d/owntone/run
RUN chmod a+x /etc/services.d/owntone/run
