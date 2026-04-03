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

# Inject proxy rotation from proxies.txt file or SEARXNG_PROXY_URL env var
PROXY_FILE="/etc/searxng/proxies.txt"
if [ -f "$PROXY_FILE" ] && [ -s "$PROXY_FILE" ]; then
  echo "[entrypoint] Loading proxies from $PROXY_FILE..."
  python3 << 'PYEOF'
import yaml

settings_path = '/etc/searxng/settings.yml'
proxy_file = '/etc/searxng/proxies.txt'

with open(settings_path, 'r') as f:
    cfg = yaml.safe_load(f)

with open(proxy_file, 'r') as f:
    proxy_urls = [line.strip() for line in f if line.strip()]

cfg.setdefault('outgoing', {})
cfg['outgoing']['proxies'] = {'all://': proxy_urls}
cfg['outgoing']['request_timeout'] = 10

with open(settings_path, 'w') as f:
    yaml.dump(cfg, f, default_flow_style=False, sort_keys=False)

print(f"[entrypoint] {len(proxy_urls)} proxy(ies) configured from file")
PYEOF
elif [ -n "$SEARXNG_PROXY_URL" ]; then
  echo "[entrypoint] Injecting proxy config from env..."
  python3 << 'PYEOF'
import os, yaml

settings_path = '/etc/searxng/settings.yml'
with open(settings_path, 'r') as f:
    cfg = yaml.safe_load(f)

proxy_urls = [p.strip() for p in os.environ['SEARXNG_PROXY_URL'].split(',') if p.strip()]
cfg.setdefault('outgoing', {})
cfg['outgoing']['proxies'] = {'all://': proxy_urls}
cfg['outgoing']['request_timeout'] = 10

with open(settings_path, 'w') as f:
    yaml.dump(cfg, f, default_flow_style=False, sort_keys=False)

print(f"[entrypoint] {len(proxy_urls)} proxy(ies) configured from env")
PYEOF
fi

# Set the SEARXNG_SETTINGS_PATH so SearXNG finds our config
export SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml

# Start SearXNG using the uwsgi command from the base image
cd /usr/local/searxng
exec python3 -m uvicorn searx.webapp:app --host 0.0.0.0 --port 8080 2>/dev/null || \
exec uwsgi --master --http-socket 0.0.0.0:8080 --module searx.webapp 2>/dev/null || \
exec python3 -c "from searx.webapp import app; app.run(host='0.0.0.0', port=8080)"
