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

# Inject proxy rotation if SEARXNG_PROXY_URL is set
# Supports single rotating proxy or multiple comma-separated:
#   SEARXNG_PROXY_URL=http://user:pass@p.webshare.io:80
#   SEARXNG_PROXY_URL=http://p1:8080,http://p2:8080,socks5://p3:1080
if [ -n "$SEARXNG_PROXY_URL" ]; then
  echo "[entrypoint] Injecting proxy config..."
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

print(f"[entrypoint] {len(proxy_urls)} proxy(ies) configured")
PYEOF
fi

# Set the SEARXNG_SETTINGS_PATH so SearXNG finds our config
export SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml

# Start SearXNG using the uwsgi command from the base image
cd /usr/local/searxng
exec python3 -m uvicorn searx.webapp:app --host 0.0.0.0 --port 8080 2>/dev/null || \
exec uwsgi --master --http-socket 0.0.0.0:8080 --module searx.webapp 2>/dev/null || \
exec python3 -c "from searx.webapp import app; app.run(host='0.0.0.0', port=8080)"
