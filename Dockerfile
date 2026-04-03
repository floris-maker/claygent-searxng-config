FROM searxng/searxng:latest

# Copy settings with proxies and secret key baked in
COPY settings.yml /etc/searxng/settings.yml

# Remove any existing limiter.toml to prevent validation errors
RUN rm -f /etc/searxng/limiter.toml

# SearXNG binds to 8080 as configured in settings.yml
EXPOSE 8080
