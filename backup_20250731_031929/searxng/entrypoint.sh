#!/bin/sh

# Create directories if they don't exist
mkdir -p /etc/searxng
mkdir -p /etc/searxng/secret
mkdir -p /var/log/searxng

# Copy settings file if it doesn't exist
if [ ! -f /etc/searxng/settings.yml ]; then
    echo "Copying settings file..."
    cp /tmp/settings.yml /etc/searxng/settings.yml || true
    chmod 644 /etc/searxng/settings.yml || true
fi

# Execute the original entrypoint
exec /sbin/tini -- /usr/local/searxng/dockerfiles/docker-entrypoint.sh "$@"