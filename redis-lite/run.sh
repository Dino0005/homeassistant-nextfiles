#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Starting Redis Lite..."

# Get Redis/Valkey version
# NOTE:
# Alpine Linux 3.20+ ships Valkey under the "redis" package name.
# In this case redis-server reports "Redis server v=8.x" even though it is Valkey.
REDIS_INFO=$(redis-server --version 2>/dev/null | head -n1)

# Extract version number
REDIS_VERSION=$(echo "$REDIS_INFO" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)

# Detect server type
if echo "$REDIS_INFO" | grep -qi "valkey"; then
    SERVER_NAME="Valkey"
    SERVER_NOTE="(Redis-compatible)"
elif [[ "$REDIS_VERSION" == 8.* ]]; then
    SERVER_NAME="Valkey"
    SERVER_NOTE="(Redis-compatible, Alpine package)"
else
    SERVER_NAME="Redis"
    SERVER_NOTE=""
fi

bashio::log.info "Server: ${SERVER_NAME} ${REDIS_VERSION} ${SERVER_NOTE}"

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
    bashio::log.info "Disk persistence enabled"
    
    # RDB Snapshots (base)
    cat >> /etc/redis.conf << EOF

# RDB Snapshots
save 900 1
save 300 10
save 60 10000
dbfilename dump.rdb
rdbcompression yes
rdbchecksum yes
EOF
    
    # AOF (Append Only File) - opzionale ma raccomandato
    if bashio::config.true 'use_aof'; then
        bashio::log.info "AOF (Append Only File) enabled - maximum data safety"
        cat >> /etc/redis.conf << EOF

# AOF - Append Only File (real-time persistence)
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
EOF
    else
        bashio::log.info "AOF disabled - using RDB snapshots only"
        cat >> /etc/redis.conf << EOF

# AOF disabled
appendonly no
EOF
    fi
else
    bashio::log.info "Persistence disabled - data stored in memory only"
    bashio::log.warning "All data will be lost on restart!"
    cat >> /etc/redis.conf << EOF

# Persistence disabled
save ""
appendonly no
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

# Check for existing persistence files
bashio::log.info "Checking for existing data files..."
RESTORE_STATUS="none"

if [ -f /data/redis/dump.rdb ]; then
    RDB_SIZE=$(ls -lh /data/redis/dump.rdb | awk '{print $5}')
    RDB_DATE=$(stat -c %y /data/redis/dump.rdb | cut -d'.' -f1)
    bashio::log.info "✓ Found RDB snapshot: ${RDB_SIZE} (${RDB_DATE})"
    RESTORE_STATUS="rdb"
fi

if [ -f /data/redis/appendonly.aof ]; then
    AOF_SIZE=$(ls -lh /data/redis/appendonly.aof | awk '{print $5}')
    AOF_DATE=$(stat -c %y /data/redis/appendonly.aof | cut -d'.' -f1)
    bashio::log.info "✓ Found AOF file: ${AOF_SIZE} (${AOF_DATE})"
    RESTORE_STATUS="aof"
fi

if [ "$RESTORE_STATUS" = "none" ]; then
    bashio::log.info "⚠ No existing data files - starting with empty database"
fi

# Display configuration summary
bashio::log.info "=========================================="
bashio::log.info "Redis Lite Configuration:"
bashio::log.info "- Max Memory: ${MAXMEMORY}"
bashio::log.info "- Eviction Policy: ${MAXMEMORY_POLICY}"
bashio::log.info "- RDB Snapshots: $(bashio::config 'save_to_disk')"
bashio::log.info "- AOF Persistence: $(bashio::config 'use_aof')"
bashio::log.info "- Password: $(bashio::config.has_value 'password' && echo 'Set' || echo 'Not set')"
bashio::log.info "- Port: 6379"
bashio::log.info "- Bind: 0.0.0.0 (accessible from other addons)"
if [ "$RESTORE_STATUS" != "none" ]; then
    bashio::log.info "- Data Recovery: Will restore from ${RESTORE_STATUS^^}"
fi
bashio::log.info "=========================================="

bashio::log.info "Starting Redis server..."

# Start Redis
exec redis-server /etc/redis.conf
