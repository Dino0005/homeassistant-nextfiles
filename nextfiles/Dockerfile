ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base
ARG NEXTCLOUD_VERSION=29.0.8
ENV NEXTCLOUD_VERSION=${NEXTCLOUD_VERSION}

# Install requirements
RUN apk add --no-cache \
    apache2 \
    apache2-ssl \
    php83 \
    php83-apache2 \
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
    php83-pdo_sqlite \
    php83-session \
    php83-simplexml \
    php83-sqlite3 \
    php83-xml \
    php83-xmlreader \
    php83-xmlwriter \
    php83-zip \
    php83-zlib \
    php83-posix \
    php83-bcmath \
    php83-gmp \
    sqlite \
    curl \
    bash

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
    sed -i 's|#LoadModule env_module|LoadModule env_module|g' /etc/apache2/httpd.conf

# Configure PHP
RUN sed -i 's|memory_limit = 128M|memory_limit = 512M|g' /etc/php83/php.ini && \
    sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 512M|g' /etc/php83/php.ini && \
    sed -i 's|post_max_size = 8M|post_max_size = 512M|g' /etc/php83/php.ini && \
    sed -i 's|max_execution_time = 30|max_execution_time = 3600|g' /etc/php83/php.ini

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD ["/run.sh"]
