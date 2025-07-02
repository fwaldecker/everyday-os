#!/bin/sh
set -e

# Create default buckets if they don't exist
create_buckets() {
    # Wait for MinIO to be ready
    until (mc alias set local http://localhost:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD} > /dev/null 2>&1); do
        echo "Waiting for MinIO to be ready..."
        sleep 1
    done

    # Create buckets if they don't exist
    for bucket in nca langfuse; do
        if ! mc ls local | grep -q "${bucket}$"; then
            echo "Creating bucket: ${bucket}"
            mc mb local/${bucket}
            mc policy set public local/${bucket}
        fi
    done

    # Set lifecycle policy for auto-deletion after 7 days
    echo "Setting lifecycle policy for buckets..."
    cat > /tmp/lifecycle.json <<EOL
{
    "Rules": [
        {
            "Expiration": {
                "Days": 7
            },
            "ID": "7-day-expiry",
            "Filter": {
                "Prefix": ""
            },
            "Status": "Enabled"
        }
    ]
}
EOL

    for bucket in nca langfuse; do
        mc ilm import local/${bucket} < /tmp/lifecycle.json
    done

    rm -f /tmp/lifecycle.json
}

# Run in background
create_buckets &

# Start MinIO
/usr/bin/docker-entrypoint.sh "$@"
