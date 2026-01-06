#!/bin/bash

# Get the directory where the script is running
SCRIPT_DIR="/volume1/backups/scripts"

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
        echo "[$(date)] $label backup Failed."
        send_pushover "$(hostname): Rclone Backup Failed ❌" "[$PO_DATE]\nAn backup of $label has failed!"
    fi
}

# ===== Run Backups ===== #
run_backup "$LOCALDIR/webdav" "$BUCKET:/webdav" "Webdav"
run_backup "$LOCALDIR/homes" "$BUCKET:/homes" "Homes"
run_backup "$LOCALDIR/media" "$BUCKET:/media" "Media"

echo "[$(date)] All tasks finished."
