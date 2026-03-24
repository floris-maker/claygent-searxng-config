FROM searxng/searxng:latest

# Copy config files into the container
COPY settings.yml /etc/searxng/settings.yml
COPY limiter.toml /etc/searxng/limiter.toml

# Generate a random secret key at build time
RUN python3 -c "import secrets; print(secrets.token_hex(32))" > /tmp/secret && \
    sed -i "s|claygent-searxng-secret-change-me|$(cat /tmp/secret)|g" /etc/searxng/settings.yml && \
    rm /tmp/secret

# Use the base image's default entrypoint and CMD — no overrides needed
