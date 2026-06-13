ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base
ARG NEXTCLOUD_VERSION=33.0.5
ENV NEXTCLOUD_VERSION=${NEXTCLOUD_VERSION}
ARG PHP_VERSION=85
ENV PHP_VERSION=${PHP_VERSION}

# Install requirements (MariaDB support included + APCu for caching + Redis support + igbinary + SMB)
RUN apk add --no-cache \
    apache2 \
    apache2-ssl \
    php${PHP_VERSION} \
    php${PHP_VERSION}-apache2 \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-ctype \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-fileinfo \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-iconv \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-json \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-openssl \
    php${PHP_VERSION}-pdo \
    php${PHP_VERSION}-pdo_mysql \
    php${PHP_VERSION}-mysqli \
    php${PHP_VERSION}-session \
    php${PHP_VERSION}-simplexml \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-xmlreader \
    php${PHP_VERSION}-xmlwriter \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-zlib \
    php${PHP_VERSION}-posix \
    php${PHP_VERSION}-pcntl \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-gmp \
    php${PHP_VERSION}-exif \
    php${PHP_VERSION}-sodium \
    php${PHP_VERSION}-sysvsem \
    php${PHP_VERSION}-apcu \
    php${PHP_VERSION}-pecl-redis \
    php${PHP_VERSION}-pecl-imagick \
    php${PHP_VERSION}-pecl-igbinary \
    php${PHP_VERSION}-pecl-imap \
    php${PHP_VERSION}-pecl-smbclient \
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

# Create /usr/bin/php symlink to php
RUN ln -sf /usr/bin/php${PHP_VERSION} /usr/bin/php && \
    ln -sf /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm || true

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

# Fix ImageMagick threading issues (prevents segmentation faults)
# ImageMagick threading conflicts with PHP JIT causing worker crashes
RUN echo 'SetEnv MAGICK_THREAD_LIMIT 1' >> /etc/apache2/httpd.conf && \
    echo 'export MAGICK_THREAD_LIMIT=1' >> /etc/profile

# Configure PHP defaults, enable PCNTL + APCu + Advanced OPcache with JIT
RUN sed -i 's|^memory_limit *=.*|memory_limit = 512M|g' /etc/php${PHP_VERSION}/php.ini && \
    sed -i 's|^upload_max_filesize *=.*|upload_max_filesize = 512M|g' /etc/php${PHP_VERSION}/php.ini && \
    sed -i 's|^post_max_size *=.*|post_max_size = 512M|g' /etc/php${PHP_VERSION}/php.ini && \
    sed -i 's|^max_execution_time *=.*|max_execution_time = 3600|g' /etc/php${PHP_VERSION}/php.ini && \
    sed -i 's/^disable_functions.*/disable_functions = /g' /etc/php${PHP_VERSION}/php.ini

# Configure OPcache without JIT (JIT causes segfault with PHP 8.4 + Apache prefork)
RUN { \
        echo 'opcache.enable=1'; \
        echo 'opcache.enable_cli=1'; \
        echo 'opcache.memory_consumption=256'; \
        echo 'opcache.interned_strings_buffer=32'; \
        echo 'opcache.max_accelerated_files=10000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.save_comments=1'; \
        echo 'opcache.jit=0'; \
        echo 'opcache.jit_buffer_size=0'; \
    } > /etc/php${PHP_VERSION}/conf.d/opcache-nextcloud.ini

# Configure APCu
RUN echo "apc.enable_cli=1" >> /etc/php${PHP_VERSION}/php.ini && \
    echo "apc.shm_size=64M" >> /etc/php${PHP_VERSION}/php.ini

# Configure igbinary serializer for APCu only
RUN echo "apc.serializer=igbinary" >> /etc/php${PHP_VERSION}/conf.d/apcu.ini

# Configure PHP sessions with persistent storage
# Sessions stored in /share/nextfiles/sessions (persistent volume)
# This ensures sessions survive container restarts and rebuilds
RUN { \
    echo 'session.save_handler = files'; \
    echo 'session.save_path = /share/nextfiles/sessions'; \
    echo 'session.gc_maxlifetime = 86400'; \
    echo 'session.cookie_lifetime = 0'; \
    echo 'session.serialize_handler = php'; \
    echo 'session.save_mode = 0600'; \
    } > /etc/php${PHP_VERSION}/conf.d/nextcloud-sessions.ini

# Setup Nextcloud cron job - runs every 5 minutes with logging
# Session cleanup cron job - runs every hour to remove expired sessions (>24h)
RUN echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" > /etc/crontabs/root && \
    echo "*/5 * * * * echo \"[CRON] Starting Nextcloud cron.php at \$(date)\" && su -s /bin/sh apache -c 'cd /var/www/nextcloud && /usr/bin/php /var/www/nextcloud/cron.php' && echo \"[CRON] Nextcloud cron.php completed\"" >> /etc/crontabs/root && \
    echo "0 * * * * echo \"[CRON] Cleaning expired sessions at \$(date)\" && find /share/nextfiles/sessions/ -name \"sess_*\" -mmin +1440 -delete && echo \"[CRON] Session cleanup completed\"" >> /etc/crontabs/root

# Copy run script
COPY run.sh /
COPY scripts/ /scripts/
RUN chmod a+x /run.sh /scripts/*.sh

CMD ["/bin/bash", "/run.sh"]
