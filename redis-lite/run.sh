#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Starting Redis Lite..."

# Get configuration
MAXMEMORY=$(bashio::config 'maxmemory')
MAXMEMORY_POLICY=$(bashio::config 'maxmemory_policy')

# Apply defaults if not set
[ -z "$MAXMEMORY" ] && MAXMEMORY="128mb"
[ -z "$MAXMEMORY_POLICY" ] && MAXMEMORY_POLICY="allkeys-lru"

# Create Redis configuration file
bashio::log.info "Creating Redis configuration..."

cat > /etc/redis.conf << EOF
# Redis Lite Configuration for Home Assistant

# Network
bind 0.0.0.0
port 6379
timeout 0
tcp-keepalive 300

# General
daemonize no
pidfile /var/run/redis.pid
loglevel notice

# Memory Management
maxmemory ${MAXMEMORY}
maxmemory-policy ${MAXMEMORY_POLICY}

# Persistence
dir /data/redis
EOF

# Configure persistence
if bashio::config.true 'save_to_disk'; then
    bashio::log.info "Persistence enabled - data will be saved to disk"
    cat >> /etc/redis.conf << EOF
save 900 1
save 300 10
save 60 10000
dbfilename dump.rdb
EOF
else
    bashio::log.info "Persistence disabled - data stored in memory only"
    cat >> /etc/redis.conf << EOF
save ""
EOF
fi

# Configure password/security
if bashio::config.has_value 'password'; then
    PASSWORD=$(bashio::config 'password')
    bashio::log.info "Password authentication enabled"
    cat >> /etc/redis.conf << EOF

# Security
requirepass "${PASSWORD}"
EOF
else
    bashio::log.info "No password set - Redis accessible without authentication"
    bashio::log.warning "Protected mode disabled - ensure port is not exposed externally!"
    cat >> /etc/redis.conf << EOF

# Security
protected-mode no
EOF
fi

# Ensure data directory exists with correct permissions
mkdir -p /data/redis
chown -R redis:redis /data/redis
chmod 755 /data/redis

# Display configuration summary
bashio::log.info "=========================================="
bashio::log.info "Redis Lite Configuration:"
bashio::log.info "- Max Memory: ${MAXMEMORY}"
bashio::log.info "- Eviction Policy: ${MAXMEMORY_POLICY}"
bashio::log.info "- Persistence: $(bashio::config 'save_to_disk')"
bashio::log.info "- Password: $(bashio::config.has_value 'password' && echo 'Set' || echo 'Not set')"
bashio::log.info "- Port: 6379"
bashio::log.info "- Bind: 0.0.0.0 (accessible from other addons)"
bashio::log.info "=========================================="

bashio::log.info "Starting Redis server..."

# Start Redis
exec redis-server /etc/redis.conf
