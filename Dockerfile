FROM searxng/searxng:latest

# Copy settings with proxies baked in
COPY settings.yml /etc/searxng/settings.yml

# Remove any existing limiter.toml to prevent validation errors
RUN rm -f /etc/searxng/limiter.toml

# Use the base image's default entrypoint and CMD
