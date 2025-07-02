#!/bin/bash

# Wait for MinIO to be ready
echo "Waiting for MinIO to be ready..."
until curl -s -f -o /dev/null "http://minio:9000/minio/health/live"; do
  echo "MinIO is not ready yet. Retrying in 5 seconds..."
  sleep 5
done

# Set up MinIO client
mc alias set minio http://minio:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

# Function to apply lifecycle policy to a bucket
apply_lifecycle_policy() {
  local bucket_name=$1
  
  # Check if bucket exists, create if it doesn't
  if ! mc ls minio/$bucket_name &>/dev/null; then
    echo "Creating bucket: $bucket_name"
    mc mb minio/$bucket_name
  fi
  
  # Create lifecycle policy JSON
  cat > /tmp/lifecycle.json <<- EOM
  {
    "Rules": [
      {
        "ID": "ExpireAllObjectsAfter7Days",
        "Status": "Enabled",
        "Filter": {
          "Prefix": ""
        },
        "Expiration": {
          "Days": 7
        }
      }
    ]
  }
EOM

  # Apply lifecycle policy
  echo "Applying 7-day expiry policy to bucket: $bucket_name"
  mc ilm import minio/$bucket_name < /tmp/lifecycle.json
  
  # Clean up
  rm -f /tmp/lifecycle.json
}

# Apply to all required buckets
for bucket in nca langfuse; do
  apply_lifecycle_policy $bucket
done

echo "MinIO initialization complete!"
