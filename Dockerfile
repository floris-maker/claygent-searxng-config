FROM searxng/searxng:latest

# Copy config files into the container
COPY settings.yml /etc/searxng/settings.yml
COPY limiter.toml /etc/searxng/limiter.toml

# Entrypoint script that replaces the Redis URL placeholder
# with the actual SEARXNG_REDIS_URL env var at runtime
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
