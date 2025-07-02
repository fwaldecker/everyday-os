#!/bin/sh

# Check if MinIO server is running
if ! curl -s -f -o /dev/null "http://localhost:9000/minio/health/live"; then
    echo "MinIO server is not responding"
    exit 1
fi

# Check if all buckets are accessible
if ! mc --insecure --no-color --json ls local >/dev/null 2>&1; then
    echo "Failed to list MinIO buckets"
    exit 1
fi

echo "MinIO is healthy"
exit 0
