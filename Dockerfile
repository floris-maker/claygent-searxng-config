FROM searxng/searxng:latest

# Copy settings (no limiter.toml — it causes schema errors in latest SearXNG)
COPY settings.yml /etc/searxng/settings.yml

# Remove any existing limiter.toml to prevent validation errors
RUN rm -f /etc/searxng/limiter.toml

# Generate a random secret key at build time
RUN python3 -c "import secrets; print(secrets.token_hex(32))" > /tmp/secret && \
    sed -i "s|claygent-searxng-secret-change-me|$(cat /tmp/secret)|g" /etc/searxng/settings.yml && \
    rm /tmp/secret

# Use the base image's default entrypoint and CMD
