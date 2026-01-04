#!/bin/bash

# Get the directory where the script is running
SCRIPT_DIR="$HOME/backup-scripts"

# Configuration file path
CONFIG_FILE="$SCRIPT_DIR/config"

# Load configuration if file exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Ensure required environment variables are set
if [ -z "$PUSHOVER_USER" ] || [ -z "$PUSHOVER_TOKEN" ]; then
    echo "Pushover credentials are not set. Exiting."
    exit 1
fi

if [ -z "$OPERATION_MODE" ] || [ -z "$OPTS" ]; then
    echo "Rclone options are not set. Exiting."
    exit 1
fi

# Pushover function
send_pushover() {
    local title="$1"
    local message="$2"
    local formatted_message
    formatted_message=$(echo -e "$message")

    curl -s -o /dev/null \
        -F "user=$PUSHOVER_USER" \
        -F "token=$PUSHOVER_TOKEN" \
        -F "title=$title" \
        -F "message=$formatted_message" \
        https://api.pushover.net/1/messages.json
}

# Backup function
run_backup() {
    local source="$1"
    local dest="$2"
    local label="$3"

    echo "[$(date)] Backing up $label."
    
    if rclone $OPERATION_MODE "$source" "$dest" $OPTS; then
        echo "[$(date)] $label backup completed successfully."
        send_pushover "$(hostname): Rclone Backup Completed ✅" "[$PO_DATE]\nAn backup of $label has completed successfully!"
    else
        echo "[$(date)] $label backup failed."
        send_pushover "$(hostname): Rclone Backup Failed ❌" "[$PO_DATE]\nAn backup of $label has failed!"
    fi
}

# Umami backup function
run_umami() {
    local source="$1"
    local dest="$2"
    local label="$3"

    mkdir -p "$UMAMI_BACKUP_DIR"

    echo "[$(date)] Creating PostgreSQL dump."
    docker exec \
        -e PGPASSWORD="$UMAMI_PG_PASSWORD" \
        "$UMAMI_PG_CONTAINER" \
        pg_dump -U "$UMAMI_PG_USER" "$UMAMI_PG_DB" > "$UMAMI_SQL_FILE"

    echo "[$(date)] Creating tar file."
    tar -zcf "$UMAMI_TAR_FILE" -C "$UMAMI_BACKUP_DIR" "$(basename "$UMAMI_SQL_FILE")"

    echo "[$(date)] Removed $(basename "$UMAMI_SQL_FILE")"
    rm "$UMAMI_SQL_FILE"

    echo "[$(date)] Uploading to $BUCKET."

    if rclone $OPERATION_MODE "$source" "$dest" $OPTS; then
        rm "$UMAMI_TAR_FILE"
        echo "[$(date)] Backup completed and $(basename "$UMAMI_TAR_FILE") has been removed."
        send_pushover "$(hostname): $label Completed ✅" "[$PO_DATE]\nAn backup of $(basename "$UMAMI_TAR_FILE") has completed successfully!"
    else
        echo "[$(date)] Upload failed and file has been retained!"
        send_pushover "$(hostname): $label Failed ❌" "[$PO_DATE]\nAn backup of $(basename "$UMAMI_TAR_FILE") has failed!"
    fi
}

# Start backup process
run_backup "$DOCKERDIR" "$BUCKET:$B2_PATH" "Docker folder"

run_umami "$UMAMI_TAR_FILE" "$BUCKET:$UMAMI_B2_PATH" "Umami Backup"

echo "[$(date)] All tasks finished."
