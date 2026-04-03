#!/bin/sh

# Replace the Redis URL placeholder with the actual env var
if [ -n "$SEARXNG_REDIS_URL" ]; then
  sed -i "s|\${SEARXNG_REDIS_URL}|${SEARXNG_REDIS_URL}|g" /etc/searxng/settings.yml
fi

# Generate a random secret key if not provided
if [ -z "$SEARXNG_SECRET_KEY" ]; then
  SEARXNG_SECRET_KEY=$(head -c 32 /dev/urandom | od -A n -t x1 | tr -d ' \n')
fi
sed -i "s|claygent-searxng-secret-change-me|${SEARXNG_SECRET_KEY}|g" /etc/searxng/settings.yml

# Inject proxy rotation from proxies.txt file or SEARXNG_PROXY_URL env var
PROXY_FILE="/etc/searxng/proxies.txt"
if [ -f "$PROXY_FILE" ] && [ -s "$PROXY_FILE" ]; then
  echo "[entrypoint] Loading proxies from $PROXY_FILE..."
  PROXY_COUNT=$(wc -l < "$PROXY_FILE" | tr -d ' ')

  # Build YAML proxy list entries
  {
    echo ""
    echo "outgoing:"
    echo "  request_timeout: 10"
    echo "  proxies:"
    echo "    all://:"
    while IFS= read -r line || [ -n "$line" ]; do
      line=$(echo "$line" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      [ -z "$line" ] && continue
      echo "    - $line"
    done < "$PROXY_FILE"
  } >> /etc/searxng/settings.yml

  echo "[entrypoint] ${PROXY_COUNT} proxy(ies) configured from file"
elif [ -n "$SEARXNG_PROXY_URL" ]; then
  echo "[entrypoint] Injecting proxy config from env..."
  {
    echo ""
    echo "outgoing:"
    echo "  request_timeout: 10"
    echo "  proxies:"
    echo "    all://:"
    echo "$SEARXNG_PROXY_URL" | tr ',' '\n' | while IFS= read -r p; do
      p=$(echo "$p" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      [ -z "$p" ] && continue
      echo "    - $p"
    done
  } >> /etc/searxng/settings.yml
  echo "[entrypoint] Proxy(ies) configured from env"
fi

# Set the SEARXNG_SETTINGS_PATH so SearXNG finds our config
export SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml

# Start SearXNG using the uwsgi command from the base image
cd /usr/local/searxng
exec python3 -m uvicorn searx.webapp:app --host 0.0.0.0 --port 8080 2>/dev/null || \
exec uwsgi --master --http-socket 0.0.0.0:8080 --module searx.webapp 2>/dev/null || \
exec python3 -c "from searx.webapp import app; app.run(host='0.0.0.0', port=8080)"
