#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Get the directory where the script is running
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration file path
CONFIG_FILE="$SCRIPT_DIR/config"

# Load configuration if file exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found at $CONFIG_FILE"
    exit 1
fi

log() {
    echo "[$(date)] $*"
}

require_env() {
    local name="$1"
    if [ -z "${!name:-}" ]; then
        log "Missing required config: $name"
        exit 1
    fi
}

# Ensure required environment variables are set
require_env "PUSHOVER_USER"
require_env "PUSHOVER_TOKEN"
require_env "OPERATION_MODE"
require_env "RCLONE_OPTS"

# Pushover function
send_pushover() {
    local title="$1"
    local message="$2"
    local formatted_message
    formatted_message=$(printf '%b' "$message")

    if ! curl -s -o /dev/null \
        -F "user=$PUSHOVER_USER" \
        -F "token=$PUSHOVER_TOKEN" \
        -F "title=$title" \
        -F "message=$formatted_message" \
        https://api.pushover.net/1/messages.json; then
        log "Pushover notification failed: $title"
    fi
}

# Backup function
run_backup() {
    local source="$1"
    local dest="$2"
    local label="$3"

    log "Backing up $label."
    
    if rclone "$OPERATION_MODE" "$source" "$dest" "${RCLONE_OPTS[@]}"; then
        log "$label backup completed successfully."
        send_pushover "$(hostname): Rclone Backup Completed ✅" "[$PO_DATE]\nA backup of $label has completed successfully!"
    else
        log "$label backup failed."
        send_pushover "$(hostname): Rclone Backup Failed ❌" "[$PO_DATE]\nA backup of $label has failed!"
    fi
}

# Umami backup function
run_umami() {
    local source="$1"
    local dest="$2"
    local label="$3"

    require_env "UMAMI_BACKUP_DIR"
    require_env "UMAMI_PG_CONTAINER"
    require_env "UMAMI_PG_PASSWORD"
    require_env "UMAMI_PG_USER"
    require_env "UMAMI_PG_DB"
    require_env "UMAMI_SQL_FILE"
    require_env "UMAMI_TAR_FILE"
    require_env "BUCKET"

    mkdir -p "$UMAMI_BACKUP_DIR"

    log "Creating PostgreSQL dump."
    if ! docker exec \
        -e PGPASSWORD="$UMAMI_PG_PASSWORD" \
        "$UMAMI_PG_CONTAINER" \
        pg_dump -U "$UMAMI_PG_USER" "$UMAMI_PG_DB" > "$UMAMI_SQL_FILE"; then
        log "PostgreSQL dump failed."
        send_pushover "$(hostname): $label Failed ❌" "[$PO_DATE]\nA backup of $label has failed!"
        return 1
    fi

    log "Creating tar file."
    if ! tar -zcf "$UMAMI_TAR_FILE" -C "$UMAMI_BACKUP_DIR" "$(basename "$UMAMI_SQL_FILE")"; then
        log "Tar creation failed."
        send_pushover "$(hostname): $label Failed ❌" "[$PO_DATE]\nA backup of $label has failed!"
        return 1
    fi

    log "Removed $(basename "$UMAMI_SQL_FILE")"
    rm "$UMAMI_SQL_FILE"

    log "Uploading to $BUCKET."

    if rclone "$OPERATION_MODE" "$source" "$dest" "${RCLONE_OPTS[@]}"; then
        rm "$UMAMI_TAR_FILE"
        log "Backup completed and $(basename "$UMAMI_TAR_FILE") has been removed."
        send_pushover "$(hostname): $label Completed ✅" "[$PO_DATE]\nA backup of $(basename "$UMAMI_TAR_FILE") has completed successfully!"
    else
        log "Upload failed and file has been retained!"
        send_pushover "$(hostname): $label Failed ❌" "[$PO_DATE]\nA backup of $(basename "$UMAMI_TAR_FILE") has failed!"
    fi
}

# Start backup process
run_backup "$DOCKERDIR" "$BUCKET:$B2_PATH" "Docker folder"

run_umami "$UMAMI_TAR_FILE" "$BUCKET:$UMAMI_B2_PATH" "Umami Backup"

log "All tasks finished."
