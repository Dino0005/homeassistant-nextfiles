ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Redis
RUN apk add --no-cache \
    redis \
    bash

# Create data directory
RUN mkdir -p /data/redis

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

# Expose Redis port
EXPOSE 6379

CMD ["/run.sh"]
