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

# Set the SEARXNG_SETTINGS_PATH so SearXNG finds our config
export SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml

# Start SearXNG using the uwsgi command from the base image
cd /usr/local/searxng
exec python3 -m uvicorn searx.webapp:app --host 0.0.0.0 --port 8080 2>/dev/null || \
exec uwsgi --master --http-socket 0.0.0.0:8080 --module searx.webapp 2>/dev/null || \
exec python3 -c "from searx.webapp import app; app.run(host='0.0.0.0', port=8080)"
