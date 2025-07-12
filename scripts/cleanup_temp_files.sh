#!/bin/bash

# Cleanup script for temporary files
# Removes files older than 1 hour from temporary directories

# Set the directories to clean
TEMP_DIRS=(
    "/data/tmp"
    "/tmp"
    "/root/everyday-os/shared/tmp"
)

# Maximum age in days (1 week)
MAX_AGE_DAYS=7

# Log file
LOG_FILE="/var/log/cleanup_temp_files.log"

echo "[$(date)] Starting cleanup of temporary files..." | tee -a "$LOG_FILE"

for DIR in "${TEMP_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        echo "Cleaning up directory: $DIR" | tee -a "$LOG_FILE"
        find "$DIR" -type f -mtime +$MAX_AGE_DAYS -delete -print 2>&1 | tee -a "$LOG_FILE"
        # Remove empty directories
        find "$DIR" -mindepth 1 -type d -empty -delete 2>&1 | tee -a "$LOG_FILE"
    else
        echo "Directory does not exist: $DIR" | tee -a "$LOG_FILE"
    fi
done

echo "[$(date)] Cleanup completed" | tee -a "$LOG_FILE"
