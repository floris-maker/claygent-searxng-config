FROM searxng/searxng:latest

# Copy settings (no limiter.toml — it causes schema errors in latest SearXNG)
COPY settings.yml /etc/searxng/settings.yml

# Copy proxy list (1000 rotating proxies, one per line)
COPY proxies.txt /etc/searxng/proxies.txt

# Remove any existing limiter.toml to prevent validation errors
RUN rm -f /etc/searxng/limiter.toml

# Copy and set custom entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
