#!/bin/sh

# Replace the Redis URL placeholder with the actual env var
if [ -n "$SEARXNG_REDIS_URL" ]; then
  sed -i "s|\${SEARXNG_REDIS_URL}|${SEARXNG_REDIS_URL}|g" /etc/searxng/settings.yml
fi

# Generate a random secret key if not provided
if [ -z "$SEARXNG_SECRET_KEY" ]; then
  SEARXNG_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
fi
sed -i "s|claygent-searxng-secret-change-me|${SEARXNG_SECRET_KEY}|g" /etc/searxng/settings.yml

# Start SearXNG (default command from the base image)
exec /usr/local/searxng/dockerfiles/docker-entrypoint.sh
