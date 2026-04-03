FROM searxng/searxng:latest

# Copy settings with proxies and secret key baked in
COPY settings.yml /etc/searxng/settings.yml

# Remove any existing limiter.toml to prevent validation errors
RUN rm -f /etc/searxng/limiter.toml

# Set the settings path so SearXNG finds our config
ENV SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml

# SearXNG binds to 8080 as configured in settings.yml
ENV PORT=8080
EXPOSE 8080
