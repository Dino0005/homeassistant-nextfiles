ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base
ARG NEXTCLOUD_VERSION=32.0.6
ENV NEXTCLOUD_VERSION=${NEXTCLOUD_VERSION}

# Install requirements (MariaDB support included + APCu for caching + Redis support + igbinary + SMB)
RUN apk add --no-cache \
    apache2 \
    apache2-ssl \
    php83 \
    php83-apache2 \
    php83-cli \
    php83-fpm \
    php83-ctype \
    php83-curl \
    php83-dom \
    php83-fileinfo \
    php83-gd \
    php83-iconv \
    php83-intl \
    php83-json \
    php83-mbstring \
    php83-opcache \
    php83-openssl \
    php83-pdo \
    php83-pdo_mysql \
    php83-mysqli \
    php83-session \
    php83-simplexml \
    php83-xml \
    php83-xmlreader \
    php83-xmlwriter \
    php83-zip \
    php83-zlib \
    php83-posix \
    php83-pcntl \
    php83-bcmath \
    php83-gmp \
    php83-exif \
    php83-sodium \
    php83-sysvsem \
    php83-apcu \
    php83-pecl-redis \
    php83-pecl-imagick \
    php83-pecl-igbinary \
    php83-imap \
    php83-pecl-smbclient \
    mariadb-client \
    samba-client \
    netcat-openbsd \
    curl \
    bash \
    dcron \
    s6-overlay \
    ffmpeg \
    imagemagick \
    imagemagick-pdf \
    imagemagick-heic \
    imagemagick-svg \
    imagemagick-webp \
    ghostscript \
    perl \
    exiftool \
    sqlite \
    wget

# Create /usr/bin/php symlink to php83
RUN ln -sf /usr/bin/php83 /usr/bin/php && \
    ln -sf /usr/sbin/php-fpm83 /usr/sbin/php-fpm || true

# Download and extract Nextcloud
WORKDIR /var/www
RUN curl -sSL https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2 | tar -xj && \
    chown -R apache:apache nextcloud && \
    chmod -R 755 nextcloud

# Configure Apache
RUN sed -i 's|/var/www/localhost/htdocs|/var/www/nextcloud|g' /etc/apache2/httpd.conf && \
    sed -i 's|AllowOverride None|AllowOverride All|g' /etc/apache2/httpd.conf && \
    sed -i 's|Listen 80|Listen 8080|g' /etc/apache2/httpd.conf && \
    sed -i 's|#LoadModule rewrite_module|LoadModule rewrite_module|g' /etc/apache2/httpd.conf && \
    sed -i 's|#LoadModule headers_module|LoadModule headers_module|g' /etc/apache2/httpd.conf && \
    sed -i 's|#LoadModule env_module|LoadModule env_module|g' /etc/apache2/httpd.conf && \
    sed -i 's|#LoadModule setenvif_module|LoadModule setenvif_module|g' /etc/apache2/httpd.conf

# Add MIME types for Nextcloud
RUN echo "AddType application/javascript .js .mjs" >> /etc/apache2/httpd.conf && \
    echo "AddType application/json .map" >> /etc/apache2/httpd.conf && \
    echo "AddType font/otf .otf" >> /etc/apache2/httpd.conf

# Configure PHP defaults, enable PCNTL + APCu + Advanced OPcache with JIT (PHP 8.3)
RUN sed -i 's|^memory_limit *=.*|memory_limit = 512M|g' /etc/php83/php.ini && \
    sed -i 's|^upload_max_filesize *=.*|upload_max_filesize = 512M|g' /etc/php83/php.ini && \
    sed -i 's|^post_max_size *=.*|post_max_size = 512M|g' /etc/php83/php.ini && \
    sed -i 's|^max_execution_time *=.*|max_execution_time = 3600|g' /etc/php83/php.ini && \
    sed -i 's/^disable_functions.*/disable_functions = /g' /etc/php83/php.ini

# Configure OPcache with JIT (use dedicated config file for reliability)
RUN { \
        echo 'opcache.enable=1'; \
        echo 'opcache.enable_cli=1'; \
        echo 'opcache.memory_consumption=256'; \
        echo 'opcache.interned_strings_buffer=32'; \
        echo 'opcache.max_accelerated_files=10000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.save_comments=1'; \
        echo 'opcache.jit=1255'; \
        echo 'opcache.jit_buffer_size=128M'; \
    } > /etc/php83/conf.d/opcache-nextcloud.ini

# Configure APCu
RUN echo "apc.enable_cli=1" >> /etc/php83/php.ini && \
    echo "apc.shm_size=64M" >> /etc/php83/php.ini

# Configure igbinary serializer for APCu only
RUN echo "apc.serializer=igbinary" >> /etc/php83/conf.d/apcu.ini

# Configure PHP sessions with persistent storage
# Sessions stored in /share/nextfiles/sessions (persistent volume)
# This ensures sessions survive container restarts and rebuilds
RUN { \
    echo 'session.save_handler = files'; \
    echo 'session.save_path = /share/nextfiles/sessions'; \
    echo 'session.gc_maxlifetime = 86400'; \
    echo 'session.cookie_lifetime = 0'; \
    echo 'session.serialize_handler = php'; \
    } > /etc/php83/conf.d/nextcloud-sessions.ini

# Setup Nextcloud cron job - runs every 5 minutes with logging
# Session cleanup cron job - runs every hour to remove expired sessions (>24h)
RUN echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" > /etc/crontabs/root && \
    echo "*/5 * * * * echo \"[CRON] Starting Nextcloud cron.php at \$(date)\" && su -s /bin/sh apache -c 'cd /var/www/nextcloud && /usr/bin/php /var/www/nextcloud/cron.php' && echo \"[CRON] Nextcloud cron.php completed\"" >> /etc/crontabs/root && \
    echo "0 * * * * echo \"[CRON] Cleaning expired sessions at \$(date)\" && find /share/nextfiles/sessions/ -name \"sess_*\" -mmin +1440 -delete && echo \"[CRON] Session cleanup completed\"" >> /etc/crontabs/root

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD ["/run.sh"]
