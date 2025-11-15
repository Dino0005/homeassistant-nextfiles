#!/usr/bin/env bash
set -e

if [ -f /data/options.json ]; then
  HOST_PATH=$(jq -r .host_path /data/options.json)
  REQUIRE_API_TOKEN=$(jq -r .require_api_token /data/options.json)
  API_TOKEN=$(jq -r .api_token /data/options.json)
  TOKEN_SECRET=$(jq -r .token_secret /data/options.json)
  DEFAULT_TTL=$(jq -r .default_link_ttl_minutes /data/options.json)
  AUTO_CLEANUP_DAYS=$(jq -r .auto_cleanup_days /data/options.json)
  CLEANUP_INTERVAL=$(jq -r .cleanup_interval_minutes /data/options.json)
fi

: ${HOST_PATH:="/share/nextfiles"}
: ${REQUIRE_API_TOKEN:=false}
: ${API_TOKEN:=""}
: ${TOKEN_SECRET:="change-this-to-a-random-secret-key"}
: ${DEFAULT_TTL:=1440}
: ${AUTO_CLEANUP_DAYS:=0}
: ${CLEANUP_INTERVAL:=60}

mkdir -p "$HOST_PATH"
chown -R 1000:1000 "$HOST_PATH" || true

export NEXTFILES_STORAGE_PATH="$HOST_PATH"
export NEXTFILES_REQUIRE_API_TOKEN="$REQUIRE_API_TOKEN"
export NEXTFILES_API_TOKEN="$API_TOKEN"
export TOKEN_SECRET="$TOKEN_SECRET"
export NEXTFILES_DEFAULT_TTL="${DEFAULT_TTL}"
export NEXTFILES_AUTO_CLEANUP_DAYS="${AUTO_CLEANUP_DAYS}"
export NEXTFILES_CLEANUP_INTERVAL="${CLEANUP_INTERVAL}"

exec gunicorn --workers 2 --bind 0.0.0.0:8099 app:app
