ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base
ARG NEXTCLOUD_VERSION=32.0.3
ENV NEXTCLOUD_VERSION=${NEXTCLOUD_VERSION}

# Install requirements (MariaDB support included + APCu for caching)
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
    mariadb-client \
    curl \
    bash \
    dcron \
    s6-overlay

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

# Configure PHP defaults and enable PCNTL + APCu
RUN sed -i 's|^memory_limit *=.*|memory_limit = 512M|g' /etc/php83/php.ini && \
    sed -i 's|^upload_max_filesize *=.*|upload_max_filesize = 512M|g' /etc/php83/php.ini && \
    sed -i 's|^post_max_size *=.*|post_max_size = 512M|g' /etc/php83/php.ini && \
    sed -i 's|^max_execution_time *=.*|max_execution_time = 3600|g' /etc/php83/php.ini && \
    echo "opcache.interned_strings_buffer=16" >> /etc/php83/php.ini && \
    echo "apc.enable_cli=1" >> /etc/php83/php.ini && \
    sed -i 's/^disable_functions.*/disable_functions = /g' /etc/php83/php.ini

# Setup Nextcloud cron job - runs every 5 minutes with logging
RUN echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" > /etc/crontabs/root && \
    echo "*/5 * * * * echo \"[CRON] Starting Nextcloud cron.php at \$(date)\" && su -s /bin/sh apache -c 'cd /var/www/nextcloud && /usr/bin/php /var/www/nextcloud/cron.php' && echo \"[CRON] Nextcloud cron.php completed\"" >> /etc/crontabs/root

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD ["/run.sh"]
